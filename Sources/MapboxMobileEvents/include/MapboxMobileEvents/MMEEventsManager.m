#import <CoreLocation/CoreLocation.h>
#import <CoreFoundation/CoreFoundation.h>
#if TARGET_OS_MACOS
#import <Cocoa/Cocoa.h>
#elif TARGET_OS_IOS || TARGET_OS_TVOS
#import <UIKit/UIKit.h>
#endif

#import "MMEEventsManager.h"
#import "MMEEventsManager_Private.h"
#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMECategoryLoader.h"
#import "MMECommonEventData.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEDispatchManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEMetricsManager.h"
#import "MMETimerManager.h"
#import "MMEUIApplicationWrapper.h"
#import "MMEUniqueIdentifier.h"
#import "MMEEventLogger.h"
#import "NSBundle+MMEMobileEvents.h"

#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEAPIClient () <MMEAPIClient>
@end

// MARK: -

@interface MMEEventsManager () <MMELocationManagerDelegate>

@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) MMETimerManager *timerManager;
@property (nonatomic) MMEDispatchManager *dispatchManager;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

// MARK: -

@implementation MMEEventsManager

+ (instancetype)sharedManager {
    static MMEEventsManager *_sharedManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        [MMECategoryLoader loadCategories];
        _sharedManager = [MMEEventsManager.alloc initShared];
    });
    
    return _sharedManager;
}

- (instancetype)init {
    return self.class.sharedManager;
}

- (instancetype)initShared {
    if (self = [super init]) {
        _paused = YES;
        _eventQueue = [NSMutableArray array];
        _commonEventData = [[MMECommonEventData alloc] init];
        _uniqueIdentifer = [[MMEUniqueIdentifier alloc] initWithTimeInterval:NSUserDefaults.mme_configuration.mme_identifierRotationInterval];
        _application = [[MMEUIApplicationWrapper alloc] init];
        _dispatchManager = [[MMEDispatchManager alloc] init];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self pauseMetricsCollection];
}

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion {
        @try {
            if (self.apiClient) {
                [NSUserDefaults.mme_configuration mme_setAccessToken:accessToken];
                return;
            }

            self.apiClient = [[MMEAPIClient alloc] initWithAccessToken:accessToken
                                                         userAgentBase:userAgentBase
                                                        hostSDKVersion:hostSDKVersion];

            __weak __typeof__(self) weakSelf = self;
            void(^initialization)(void) = ^{
                __strong __typeof__(weakSelf) strongSelf = weakSelf;

                if (strongSelf == nil) {
                    return;
                }

                // Issue: https://github.com/mapbox/mapbox-events-ios/issues/271
#if !TARGET_OS_SIMULATOR // don't send pending metrics from the simulator
                [strongSelf sendPendingMetricsEvent];
#endif
                
                [NSNotificationCenter.defaultCenter addObserver:strongSelf
                                                       selector:@selector(pauseOrResumeMetricsCollectionIfRequired)
                                                           name:UIApplicationDidEnterBackgroundNotification
                                                         object:nil];
                [NSNotificationCenter.defaultCenter addObserver:strongSelf
                                                       selector:@selector(pauseOrResumeMetricsCollectionIfRequired)
                                                           name:UIApplicationDidBecomeActiveNotification
                                                         object:nil];

                if (@available(iOS 9.0, *)) {
                    [NSNotificationCenter.defaultCenter addObserver:strongSelf
                                                           selector:@selector(powerStateDidChange:)
                                                               name:NSProcessInfoPowerStateDidChangeNotification
                                                             object:nil];
                }

                strongSelf.paused = YES;
                strongSelf.locationManager.delegate = strongSelf;
                [strongSelf resumeMetricsCollection];

                strongSelf.timerManager = [[MMETimerManager alloc]
                                           initWithTimeInterval:NSUserDefaults.mme_configuration.mme_eventFlushInterval
                                           target:strongSelf
                                           selector:@selector(flush)];
            };

            [self.dispatchManager scheduleBlock:initialization afterDelay:NSUserDefaults.mme_configuration.mme_startupDelay];
        }
        @catch(NSException *except) {
            [self reportException:except];
        }
}

#pragma mark - Enable/Disable

- (void)disableLocationMetrics {
    @try {
        NSUserDefaults.mme_configuration.mme_isCollectionEnabled = NO;
        [self.locationManager stopUpdatingLocation];
    }
    @catch (NSException *except) {
        [self reportException:except];
    }
}

#pragma mark - NSNotifications

- (void)powerStateDidChange:(NSNotification *)notification {
    // From https://github.com/mapbox/mapbox-events-ios/issues/44 it looks like
    // `NSProcessInfoPowerStateDidChangeNotification` can be sent from a thread other than the main
    // thread.
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf pauseOrResumeMetricsCollectionIfRequired];
    });
}

- (void)pauseOrResumeMetricsCollectionIfRequired {
    @try {
        BOOL appIsInBackground = (self.application.applicationState == UIApplicationStateBackground);

        // check for existing background task status, flush the event queue if needed
        if (appIsInBackground && _backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            MMELOG(MMELogInfo, MMEDebugEventTypeBackgroundTask, ([NSString stringWithFormat:@"Initiated background task: %@, instance: %@",@(self.backgroundTaskIdentifier),self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            
            _backgroundTaskIdentifier = [self.application beginBackgroundTaskWithExpirationHandler:^{
                MMELOG(MMELogInfo, MMEDebugEventTypeBackgroundTask, ([NSString stringWithFormat:@"Ending background task: %@, instance: %@",@(self.backgroundTaskIdentifier),self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
                
                UIBackgroundTaskIdentifier taskId = self.backgroundTaskIdentifier;
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                [self.application endBackgroundTask:taskId];
            }];
            
            [self flush];
        }
                
        [self processAuthorizationStatus:[self.locationManager locationAuthorization] andApplicationState:self.application.applicationState];
    }
    @catch(NSException *except) {
        [self reportException:except];
    }
}

- (void)processAuthorizationStatus:(CLAuthorizationStatus)authStatus andApplicationState:(UIApplicationState)applicationState {
    // check the system authorization status, then decide what we should be doing
    if (authStatus == kCLAuthorizationStatusAuthorizedAlways) {
        if (((applicationState != UIApplicationStateBackground && NSUserDefaults.mme_configuration.mme_isCollectionEnabled)
         || (applicationState == UIApplicationStateBackground && NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground))
         && self.isPaused) {
            [self resumeMetricsCollection];
        } else if ((applicationState == UIApplicationStateBackground
                   && NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground == NO)
                   || NSUserDefaults.mme_configuration.mme_isCollectionEnabled == NO) {
            [self pauseMetricsCollection];
        }
    } else if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (NSUserDefaults.mme_configuration.mme_isCollectionEnabled && self.paused) {  // Prevent blue status bar
            [self resumeMetricsCollection];
        } else if (applicationState == UIApplicationStateBackground) { // check for user preferences
            [self pauseMetricsCollection];
        } else if (!NSUserDefaults.mme_configuration.mme_isCollectionEnabled) {
            [self pauseMetricsCollection];
        }
    } else {
        [self pauseMetricsCollection];
    }
}

- (void)flush {
    @try {
        if (self.paused) {
            return;
        }

        if (NSUserDefaults.mme_configuration.mme_accessToken == nil) {
            return;
        }

        if (self.eventQueue.count == 0) {
            return;
        }

        [self sendTelemetryMetricsEvent];
        NSArray *events = [self.eventQueue copy];
        [self postEvents:events];
        [self resetEventQueuing];

        if (self.delegate && [self.delegate respondsToSelector:@selector(eventsManager:didSendEvents:)]) {
            [self.delegate eventsManager:self didSendEvents:events];
        }

        MMELOG(MMELogInfo, MMEDebugEventTypeFlush, ([NSString stringWithFormat:@"flush, instance: %@",self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
    }
    @catch(NSException *except) {
        [self reportException:except];
    }
}

- (void)resetEventQueuing {
    @try {
        [self.eventQueue removeAllObjects];
        [self.timerManager cancel];
    }
    @catch(NSException *except) {
        [self reportException:except];
    }

}

- (void)postEvents:(NSArray *)events {
    @try {
        __weak __typeof__(self) weakSelf = self;
        [self.apiClient postEvents:events completionHandler:^(NSError * _Nullable error) {
            @try {
                __strong __typeof__(weakSelf) strongSelf = weakSelf;

                if (error) {
                    [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:error]];
                } else {
                    MMELOG(MMELogInfo, MMEDebugEventTypePost, ([NSString stringWithFormat:@"post: %@, instance: %@", @(events.count),self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
                }

                if (strongSelf.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                    MMELOG(MMELogInfo, MMEDebugEventTypeBackgroundTask, ([NSString stringWithFormat:@"Ending background task: %@, instance: %@",@(self.backgroundTaskIdentifier),self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
                    
                    [strongSelf.application endBackgroundTask:strongSelf.backgroundTaskIdentifier];
                    strongSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                }
            }
            @catch(NSException *except) {
                [self reportException:except];
            }
        }];
    }
    @catch(NSException *except) {
        [self reportException:except];
    }
}

- (void)sendTurnstileEvent {
    @try {
        if (self.nextTurnstileSendDate && ([NSDate.date timeIntervalSinceDate:self.nextTurnstileSendDate] < 0)) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstile, ([NSString stringWithFormat:@"Turnstile event already sent; waiting until %@ to send another one, instance: %@", self.nextTurnstileSendDate, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        if (!NSUserDefaults.mme_configuration.mme_accessToken) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No access token sent - can not send turntile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        if (!NSUserDefaults.mme_configuration.mme_legacyUserAgentBase) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No user agent base set - can not send turntile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        if (!NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No host SDK version set - can not send turntile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        if (!self.commonEventData.vendorId) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No vendor id available - can not send turntile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        if (!self.commonEventData.model) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No model available - can not send turntile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        if (!self.commonEventData.osVersion) {
            MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No iOS version available - can not send turntile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            return;
        }

        NSMutableDictionary *turnstileEventAttributes = [[NSMutableDictionary alloc] init];
        turnstileEventAttributes[MMEEventKeyEvent] = MMEEventTypeAppUserTurnstile;
        turnstileEventAttributes[MMEEventKeyCreated] = [MMEDate.iso8601DateFormatter stringFromDate:[NSDate date]];
        turnstileEventAttributes[MMEEventKeyVendorID] = self.commonEventData.vendorId;
        // MMEEventKeyDevice is synonomous with MMEEventKeyModel but the server will only accept "device" in turnstile events
        turnstileEventAttributes[MMEEventKeyDevice] = self.commonEventData.model;
        turnstileEventAttributes[MMEEventKeyOperatingSystem] = self.commonEventData.osVersion;
        turnstileEventAttributes[MMEEventSDKIdentifier] = NSUserDefaults.mme_configuration.mme_legacyUserAgentBase;
        turnstileEventAttributes[MMEEventSDKVersion] = NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion;
        turnstileEventAttributes[MMEEventKeyEnabledTelemetry] = @(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
        turnstileEventAttributes[MMEEventKeyLocationEnabled] = @(CLLocationManager.locationServicesEnabled);
        turnstileEventAttributes[MMEEventKeyLocationAuthorization] = [self.locationManager locationAuthorizationString];
        turnstileEventAttributes[MMEEventKeySkuId] = self.skuId ?: NSNull.null;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
        if (@available(iOS 14, macOS 11.0, watchOS 7.0, tvOS 14.0, *)) {
            turnstileEventAttributes[MMEEventKeyAccuracyAuthorization] = [self.locationManager accuracyAuthorizationString];
        }
#endif

        MMEEvent *turnstileEvent = [MMEEvent turnstileEventWithAttributes:turnstileEventAttributes];
        
        MMELOG(MMELogInfo, MMEDebugEventTypeTurnstile, ([NSString stringWithFormat:@"Sending turnstile event: %@, instance: %@", turnstileEvent , self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));

        __weak __typeof__(self) weakSelf = self;
        [self.apiClient postEvent:turnstileEvent completionHandler:^(NSError * _Nullable error) {
            @try {
                __strong __typeof__(weakSelf) strongSelf = weakSelf;

                if (error) {
                    MMELOG(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"Could not send turnstile event: %@, instance: %@", [error localizedDescription] , self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
                    return;
                }

                [strongSelf updateNextTurnstileSendDate];
                
                MMELOG(MMELogInfo, MMEDebugEventTypeTurnstile, ([NSString stringWithFormat:@"Sent turnstile event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            }
            @catch(NSException *except) {
                [self reportException:except];
            }
        }];
    }
    @catch(NSException *except) {
        [self reportException:except];
    }
}

- (void)sendPendingMetricsEvent {
    MMEEvent *pendingMetricsEvent = [MMEMetricsManager.sharedManager loadPendingTelemetryMetricsEvent];

    if (pendingMetricsEvent) {
        [self.apiClient postEvent:pendingMetricsEvent completionHandler:^(NSError * _Nullable error) {
            if (error) {
                [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:error]];
                return;
            }
            MMELOG(MMELogInfo, MMEDebugEventTypeTelemetryMetrics, ([NSString stringWithFormat:@"Sent pendingTelemetryMetrics event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
        }];
    }
}

- (void)sendTelemetryMetricsEvent {
    @try {
        MMEEvent *telemetryMetricsEvent = [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
        
        MMELOG(MMELogInfo, MMEDebugEventTypeTelemetryMetrics, ([NSString stringWithFormat:@"Sending telemetryMetrics event: %@, instance: %@", telemetryMetricsEvent, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
        
        if (telemetryMetricsEvent) {
            [self.apiClient postEvent:telemetryMetricsEvent completionHandler:^(NSError * _Nullable error) {
                [MMEMetricsManager.sharedManager resetMetrics];
                if (error) {
                    MMELOG(MMELogInfo, MMEDebugEventTypeTelemetryMetrics, ([NSString stringWithFormat:@"Could not send telemetryMetrics event: %@, instance: %@", [error localizedDescription], self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
                    return;
                }
                MMELOG(MMELogInfo, MMEDebugEventTypeTelemetryMetrics, ([NSString stringWithFormat:@"Sent telemetryMetrics event, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
            }];
        }
    }
    @catch(NSException *except) {
        [self reportException:except];
    }
}

- (void)enqueueEventWithName:(NSString *)name {
    [self createAndPushEventBasedOnName:name attributes:@{}];
}

- (void)enqueueEventWithName:(NSString *)name attributes:(MMEMapboxEventAttributes *)attributes {
    [self createAndPushEventBasedOnName:name attributes:attributes];
}

- (void)createAndPushEventBasedOnName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEDate *now = [MMEDate date];
    MMEEvent *event = nil;

    if ([name isEqualToString:MMEEventTypeMapLoad]) {
        event = [MMEEvent mapLoadEventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] commonEventData:self.commonEventData];
    } else if ([name isEqualToString:MMEEventTypeMapTap]) {
        event = [MMEEvent mapTapEventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] attributes:attributes];
    } else if ([name isEqualToString:MMEEventTypeMapDragEnd]) {
        event = [MMEEvent mapDragEndEventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] attributes:attributes];
    } else if ([name isEqualToString:MMEventTypeOfflineDownloadStart]) {
        event = [MMEEvent mapOfflineDownloadStartEventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] attributes:attributes];
    } else if ([name isEqualToString:MMEventTypeOfflineDownloadEnd]) {
        event = [MMEEvent mapOfflineDownloadEndEventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] attributes:attributes];
    }
    
    if ([name hasPrefix:MMENavigationEventPrefix]) {
        event = [MMEEvent navigationEventWithName:name attributes:attributes];
    }

    if ([name hasPrefix:MMEVisionEventPrefix]) {
        event = [MMEEvent visionEventWithName:name attributes:attributes];
    }
    
    if ([name hasPrefix:MMESearchEventPrefix]) {
        event = [MMEEvent searchEventWithName:name attributes:attributes];
    }

    if (event) {
        MMELOG(MMELogInfo, MMEDebugEventTypePush, ([NSString stringWithFormat:@"Pushing event: %@, instance: %@", event, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
        
        [self pushEvent:event];
    } else {
        event = [MMEEvent eventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] name:name attributes:attributes];

        MMELOG(MMELogInfo, MMEDebugEventTypePush, ([NSString stringWithFormat:@"Pushing generic event: %@, instance: %@", event, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));

        [self pushEvent:event];
    }
}

- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self.apiClient postMetadata:metadata filePaths:filePaths completionHandler:^(NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled {
    MMEEventLogger.sharedLogger.enabled = debugLoggingEnabled;
}

- (BOOL)isDebugLoggingEnabled {
    return MMEEventLogger.sharedLogger.enabled;
}

- (void)setDebugHandler:(void (^)(NSUInteger, NSString *, NSString *))handler {
    MMEEventLogger.sharedLogger.handler = handler;
}

#pragma mark - Error & Exception Reporting

- (MMEEvent *)reportError:(NSError *)eventsError {
    MMEEvent *errorEvent = nil;
    
    @try {
        if (self.delegate && [self.delegate respondsToSelector:@selector(eventsManager:didEncounterError:)]) {
            [self.delegate eventsManager:self didEncounterError:eventsError];
        }

        NSError *createError = nil;
        errorEvent = [MMEEvent crashEventReporting:eventsError error:&createError];

        if (errorEvent) {
            [self pushEvent:errorEvent];
        }
        else {
            [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:createError]];
        }
    }
    @catch(NSException *except) {
        [self reportException:except];
    }

    return errorEvent;
}

- (MMEEvent *)reportException:(NSException *)exception {
    NSError *exceptionalError = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorException userInfo:@{
        NSLocalizedDescriptionKey: @"Exception Report",
        MMEErrorUnderlyingExceptionKey: exception
    }];

    return [self reportError:exceptionalError];
}

#pragma mark - Internal API

- (void)pauseMetricsCollection {
    MMELOG(MMELogInfo, MMEDebugEventTypeMetricCollection, ([NSString stringWithFormat:@"Pausing metrics collection..., instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));

    if (self.isPaused) {
        MMELOG(MMELogInfo, MMEDebugEventTypeMetricCollection, ([NSString stringWithFormat:@"Already paused, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
        return;
    }
    
    self.paused = YES;
    [self resetEventQueuing];
    
    [self.locationManager stopUpdatingLocation];

    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Paused and location manager stopped, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)resumeMetricsCollection {
    MMELOG(MMELogInfo, MMEDebugEventTypeMetricCollection, ([NSString stringWithFormat:@"Resuming metrics collection..., instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));

    if (!self.isPaused || !NSUserDefaults.mme_configuration.mme_isCollectionEnabled) {
        MMELOG(MMELogInfo, MMEDebugEventTypeMetricCollection, ([NSString stringWithFormat:@"Already running, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
        return;
    }
    
    self.paused = NO;

    if (NSUserDefaults.mme_configuration.mme_isCollectionEnabled) {
        [self.locationManager startUpdatingLocation];
    }
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Resumed and location manager started, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)updateNextTurnstileSendDate {
    // Find the start of tomorrow and use that as the next turnstile send date. The effect of this is that
    // turnstile events can be sent as much as once per calendar day and always at the start of a session
    // when a map load happens.
    self.nextTurnstileSendDate = [NSDate.date mme_startOfTomorrow];

    MMELOG(MMELogInfo, MMEDebugEventTypeTurnstile, ([NSString stringWithFormat:@"Set next turnstile date to: %@, instance: %@", self.nextTurnstileSendDate, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)pushEvent:(MMEEvent *)event {
    if (!event) {
        return;
    }
    
    [self.eventQueue addObject:event];

    MMELOG(MMELogInfo, MMEDebugEventTypePush, ([NSString stringWithFormat:@"Added event to event queue; event queue now has %ld events, instance: %@", (long)self.eventQueue.count, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
    
    if (self.eventQueue.count >= NSUserDefaults.mme_configuration.mme_eventFlushCount) {
        [self flush];
    }
    
    if (self.eventQueue.count == 1) {
        [self.timerManager start];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(eventsManager:didEnqueueEvent:)]) {
        [self.delegate eventsManager:self didEnqueueEvent:event];
    }
}

- (id<MMELocationManager>) locationManager {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _locationManager = [[MMELocationManager alloc] init];
    });

    return _locationManager;
}

#pragma mark - MMELocationManagerDelegate

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Location manager sent %ld locations, instance: %@", (long)locations.count, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));

    const BOOL appIsInBackground = (self.application.applicationState == UIApplicationStateBackground);

    for (CLLocation *location in locations) {
        // Apply all counter beforing checking the HA filter
        if (appIsInBackground) {
            [MMEMetricsManager.sharedManager incrementLocationsInBackground];
        } else {
            [MMEMetricsManager.sharedManager incrementLocationsInForeground];
        }

        if ([self.locationManager isReducedAccuracy]) {
            [MMEMetricsManager.sharedManager incrementLocationsWithApproximateValues];
        }
        
        // Post events based on the `hao` config value.
        // 1. `hao` config value is negative - No HA Filter. Always send the event.
        // 2. `hao` value is smaller than the Location Horizontal Accuracy - Skip the event.
        CLLocationAccuracy mmeHorizontalAccuracy = NSUserDefaults.mme_configuration.mme_horizontalAccuracy;
        if (mmeHorizontalAccuracy >= 0 && location.horizontalAccuracy > mmeHorizontalAccuracy) {
            [MMEMetricsManager.sharedManager incrementLocationsDroppedBecauseOfHAF];
            continue;
        }

        MMEMutableMapboxEventAttributes *eventAttributes = [[MMEMutableMapboxEventAttributes alloc] init];
        [eventAttributes addEntriesFromDictionary:@{
            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy]),
            MMEEventKeyVerticalAccuracy: @([location mme_roundedVerticalAccuracy]),
            MMEEventKeySpeed: @([location mme_roundedSpeed]),
            MMEEventKeyCourse: @([location mme_roundedCourse])
        }];

        NSString *digest = NSUserDefaults.mme_configuration.mme_configDigestValue;
        if (digest) {
            [eventAttributes addEntriesFromDictionary:@{
                MMEEventKeyConfig: digest
            }];
        }
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130400
        if (@available(iOS 13.4, *)) {
            [eventAttributes addEntriesFromDictionary:@{
                MMEEventKeySpeedAccuracy: @([location speedAccuracy]),
                MMEEventKeyCourseAccuracy: @([location courseAccuracy])
            }];
        }
#endif

        if ([self.locationManager isReducedAccuracy]) {
            [eventAttributes addEntriesFromDictionary:@{
                MMEEventKeyApproximate: @(YES)
            }];
        }

        if ([location floor]) {
            [eventAttributes setValue:@([location floor].level) forKey:MMEEventKeyFloor];
        }

        [MMEMetricsManager.sharedManager incrementLocationsConvertedIntoEvents];

        [self pushEvent:[MMEEvent locationEventWithAttributes:eventAttributes
                                            instanceIdentifer:self.uniqueIdentifer.rollingInstanceIdentifer
                                              commonEventData:self.commonEventData]];
    }

    if ([self.delegate respondsToSelector:@selector(eventsManager:didUpdateLocations:)]) {
        [self.delegate eventsManager:self didUpdateLocations:locations];
    }
}

- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Location manager started location updates, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Location manager timed out, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager {
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Location manager automatically paused, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Location manager stopped location updates, instance: %@", self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
}

- (void)locationManager:(MMELocationManager *)locationManager didVisit:(CLVisit *)visit {
    MMELOG(MMELogInfo, MMEDebugEventTypeLocationManager, ([NSString stringWithFormat:@"Location manager visit %@, instance: %@", visit, self.uniqueIdentifer.rollingInstanceIdentifer ?: @"nil"]));
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude];
    
    MMEMutableMapboxEventAttributes *eventAttributes = [[MMEMutableMapboxEventAttributes alloc] init];
    
    [eventAttributes addEntriesFromDictionary:@{
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
        MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
        MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
        MMEEventHorizontalAccuracy: @(visit.horizontalAccuracy),
        MMEEventKeyVerticalAccuracy: @([location mme_roundedVerticalAccuracy]),
        MMEEventKeyArrivalDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.arrivalDate],
        MMEEventKeyDepartureDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.departureDate]
    }];

    if ([location floor]) {
        [eventAttributes setValue:@([location floor].level) forKey:MMEEventKeyFloor];
    }

    [self pushEvent:[MMEEvent visitEventWithAttributes:eventAttributes]];

    if ([self.delegate respondsToSelector:@selector(eventsManager:didVisit:)]) {
        [self.delegate eventsManager:self didVisit:visit];
    }
}

@end

NS_ASSUME_NONNULL_END
