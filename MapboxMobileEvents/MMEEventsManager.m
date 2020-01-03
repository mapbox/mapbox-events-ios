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
#ifdef DEBUG
#import "MMEEventLogger.h"
#endif

#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"
#import "NSUserDefaults+MMEConfiguration.h"

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

        [self sendPendingTelemetryMetricsEvent];

        __weak __typeof__(self) weakSelf = self;
        void(^initialization)(void) = ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;

            if (strongSelf == nil) {
                return;
            }

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
            strongSelf.locationManager = [[MMELocationManager alloc] init];
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
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeBackgroundTask,
                MMEEventKeyLocalDebugDescription: @"Initiated background task",
                @"Identifier": @(_backgroundTaskIdentifier)}];
            #endif
            
            _backgroundTaskIdentifier = [self.application beginBackgroundTaskWithExpirationHandler:^{
                #ifdef DEBUG
                [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                    @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                    MMEDebugEventType: MMEDebugEventTypeBackgroundTask,
                    MMEEventKeyLocalDebugDescription: @"Ending background task",
                    @"Identifier": @(self.backgroundTaskIdentifier)}];
                #endif
                [self.application endBackgroundTask:self.backgroundTaskIdentifier];
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }];
            
            [self flush];
        }
                
        [self processAuthorizationStatus:[CLLocationManager authorizationStatus] andApplicationState:self.application.applicationState];
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

        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
            @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypeFlush,
            MMEEventKeyLocalDebugDescription:@"flush"}];
        #endif
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
        NSUInteger eventsCount = events.count;

        __weak __typeof__(self) weakSelf = self;
        [self.apiClient postEvents:events completionHandler:^(NSError * _Nullable error) {
            @try {
                __strong __typeof__(weakSelf) strongSelf = weakSelf;

                if (error) {
                    #ifdef DEBUG
                    [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:error]];
                    #endif
                } else {
                    #ifdef DEBUG
                    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                        MMEDebugEventType: MMEDebugEventTypePost,
                        MMEEventKeyLocalDebugDescription: @"post",
                        @"debug.eventsCount": @(eventsCount)}];
                    #endif
                }

                if (strongSelf.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                    #ifdef DEBUG
                    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                        MMEDebugEventType: MMEDebugEventTypeBackgroundTask,
                        MMEEventKeyLocalDebugDescription: @"Ending background task",
                        @"Identifier": @(strongSelf.backgroundTaskIdentifier)}];
                    #endif
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
            NSString *debugDescription = [NSString stringWithFormat:@"Turnstile event already sent; waiting until %@ to send another one", self.nextTurnstileSendDate];
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstile,
                MMEEventKeyLocalDebugDescription: debugDescription}];
            #endif
            return;
        }

        if (!NSUserDefaults.mme_configuration.mme_accessToken) {
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstileFailed,
                MMEEventKeyLocalDebugDescription: @"No access token sent, can not send turntile event"}];
            #endif
            return;
        }

        if (!NSUserDefaults.mme_configuration.mme_legacyUserAgentBase) {
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstileFailed,
                MMEEventKeyLocalDebugDescription: @"No user agent base set, can not send turntile event"}];
            #endif
            return;
        }

        if (!NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion) {
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstileFailed,
                MMEEventKeyLocalDebugDescription: @"No host SDK version set, can not send turntile event"}];
            #endif
            return;
        }

        if (!self.commonEventData.vendorId) {
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstileFailed,
                MMEEventKeyLocalDebugDescription: @"No vendor id available, can not send turntile event"}];
            #endif
            return;
        }

        if (!self.commonEventData.model) {
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstileFailed,
                MMEEventKeyLocalDebugDescription: @"No model available, can not send turntile event"}];
            #endif
            return;
        }

        if (!self.commonEventData.osVersion) {
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,MMEDebugEventType: MMEDebugEventTypeTurnstileFailed,
                MMEEventKeyLocalDebugDescription: @"No iOS version available, can not send turntile event"}];
            #endif
            return;
        }

        NSDictionary *turnstileEventAttributes = @{
            MMEEventKeyEvent: MMEEventTypeAppUserTurnstile,
            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[NSDate date]],
            MMEEventKeyVendorID: self.commonEventData.vendorId,
            // MMEEventKeyDevice is synonomous with MMEEventKeyModel but the server will only accept "device" in turnstile events
            MMEEventKeyDevice: self.commonEventData.model,
            MMEEventKeyOperatingSystem: self.commonEventData.osVersion,
            MMEEventSDKIdentifier: NSUserDefaults.mme_configuration.mme_legacyUserAgentBase,
            MMEEventSDKVersion: NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion,
            MMEEventKeyEnabledTelemetry: @(NSUserDefaults.mme_configuration.mme_isCollectionEnabled),
            MMEEventKeyLocationEnabled: @(CLLocationManager.locationServicesEnabled),
            MMEEventKeyLocationAuthorization: CLLocationManager.mme_authorizationStatusString,
            MMEEventKeySkuId: self.skuId ?: NSNull.null
       };

        MMEEvent *turnstileEvent = [MMEEvent turnstileEventWithAttributes:turnstileEventAttributes];
        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
            @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypeTurnstile,
            MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Sending turnstile event: %@", turnstileEvent]}];
        #endif

        __weak __typeof__(self) weakSelf = self;
        [self.apiClient postEvent:turnstileEvent completionHandler:^(NSError * _Nullable error) {
            @try {
                __strong __typeof__(weakSelf) strongSelf = weakSelf;

                if (error) {
                    #ifdef DEBUG
                    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                        MMEDebugEventType: MMEDebugEventTypeTurnstile,
                        MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Could not send turnstile event: %@", error]}];
                    #endif
                    return;
                }

                [strongSelf updateNextTurnstileSendDate];
                #ifdef DEBUG
                [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                    @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                    MMEDebugEventType: MMEDebugEventTypeTurnstile,
                    MMEEventKeyLocalDebugDescription: @"Sent turnstile event"}];
                #endif
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

- (void)sendPendingTelemetryMetricsEvent {
    MMEEvent *pendingMetricsEvent = [MMEMetricsManager.sharedManager loadPendingTelemetryMetricsEvent];

    if (pendingMetricsEvent) {
        [self.apiClient postEvent:pendingMetricsEvent completionHandler:^(NSError * _Nullable error) {
            if (error) {
                #ifdef DEBUG
                [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:error]];
                #endif
                return;
            }
            #ifdef DEBUG
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                MMEDebugEventType: MMEDebugEventTypeTurnstile,
                MMEEventKeyLocalDebugDescription: @"Sent pendingTelemetryMetrics event"}];
            #endif
        }];
    }
}

- (void)sendTelemetryMetricsEvent {
    @try {
        MMEEvent *telemetryMetricsEvent = [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
            @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypeTurnstile,
            MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Sending telemetryMetrics event: %@", telemetryMetricsEvent]}];
        #endif
        if (telemetryMetricsEvent) {
            [self.apiClient postEvent:telemetryMetricsEvent completionHandler:^(NSError * _Nullable error) {
                [MMEMetricsManager.sharedManager resetMetrics];
                if (error) {
                    #ifdef DEBUG
                    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                        MMEDebugEventType: MMEDebugEventTypeTelemetryMetrics,
                        MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Could not send telemetryMetrics event: %@", error]}];
                    #endif
                    return;
                }
                #ifdef DEBUG
                [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
                    @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
                    MMEDebugEventType: MMEDebugEventTypeTurnstile,
                    MMEEventKeyLocalDebugDescription: @"Sent telemetryMetrics event"}];
                #endif
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
        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
            @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypePush,
            MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Pushing event: %@", event]}];
        #endif
        [self pushEvent:event];
    } else {
        event = [MMEEvent eventWithDateString:[MMEDate.iso8601DateFormatter stringFromDate:now] name:name attributes:attributes];
        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
            @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypePush,
            MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Pushing generic event: %@", event]}];
        #endif
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

#ifdef DEBUG
- (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled {
    MMEEventLogger.sharedLogger.enabled = debugLoggingEnabled;
}

- (BOOL)isDebugLoggingEnabled {
    return [MMEEventLogger.sharedLogger isEnabled];
}

- (void)setDebugHandler:(void (^)(MMEEvent *))handler {
    [MMEEventLogger.sharedLogger setHandler:handler];
}
#endif

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
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeMetricCollection,
        MMEEventKeyLocalDebugDescription: @"Pausing metrics collection..."}];
    #endif

    if (self.isPaused) {
        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypeMetricCollection,
            MMEEventKeyLocalDebugDescription: @"Already paused"}];
        #endif
        return;
    }
    
    self.paused = YES;
    [self resetEventQueuing];
    
    [self.locationManager stopUpdatingLocation];
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: @"Paused and location manager stopped"}];
    #endif
}

- (void)resumeMetricsCollection {
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeMetricCollection,
        MMEEventKeyLocalDebugDescription: @"Resuming metrics collection..."}];
    #endif

    if (!self.isPaused || !NSUserDefaults.mme_configuration.mme_isCollectionEnabled) {
        #ifdef DEBUG
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
            @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
            MMEDebugEventType: MMEDebugEventTypeMetricCollection,
            MMEEventKeyLocalDebugDescription: @"Already running"}];
        #endif
        return;
    }
    
    self.paused = NO;

    if (NSUserDefaults.mme_configuration.mme_isCollectionEnabled) {
        [self.locationManager startUpdatingLocation];
    }
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: @"Resumed and location manager started"}];
    #endif
}

- (void)updateNextTurnstileSendDate {
    // Find the start of tomorrow and use that as the next turnstile send date. The effect of this is that
    // turnstile events can be sent as much as once per calendar day and always at the start of a session
    // when a map load happens.
    self.nextTurnstileSendDate = [NSDate.date mme_startOfTomorrow];
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeTurnstile,
        MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Set next turnstile date to: %@", self.nextTurnstileSendDate]}];
    #endif
}

- (void)pushEvent:(MMEEvent *)event {
    if (!event) {
        return;
    }
    
    [self.eventQueue addObject:event];
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypePush,
        MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Added event to event queue; event queue now has %ld events", (long)self.eventQueue.count]}];
    #endif
    
    if (self.eventQueue.count >= NSUserDefaults.mme_configuration.mme_eventFlushCount) {
        [self flush];
    }
    
    if (self.eventQueue.count == 1) {
        [self.timerManager start];
    }
}

#pragma mark - MMELocationManagerDelegate

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Location manager sent %ld locations", (long)locations.count]}];
    #endif
    
    for (CLLocation *location in locations) {        
        MMEMapboxEventAttributes *eventAttributes = @{
            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])};

        [self pushEvent:[MMEEvent locationEventWithAttributes:eventAttributes
                                            instanceIdentifer:self.uniqueIdentifer.rollingInstanceIdentifer
                                              commonEventData:self.commonEventData]];
    }

    if ([self.delegate respondsToSelector:@selector(eventsManager:didUpdateLocations:)]) {
        [self.delegate eventsManager:self didUpdateLocations:locations];
    }
}

#ifdef DEBUG
- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: @"Location manager started location updates"}];
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: @"Location manager timed out"}];
}

- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager {
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: @"Location manager automatically paused"}];
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: @"Location manager stopped location updates"}];
}
#endif

- (void)locationManager:(MMELocationManager *)locationManager didVisit:(CLVisit *)visit {
    #ifdef DEBUG
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{
        @"instance": self.uniqueIdentifer.rollingInstanceIdentifer,
        MMEDebugEventType: MMEDebugEventTypeLocationManager,
        MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Location manager visit %@", visit]}];
    #endif
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude];
    MMEMapboxEventAttributes *eventAttributes = @{
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
        MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
        MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
        MMEEventHorizontalAccuracy: @(visit.horizontalAccuracy),
        MMEEventKeyArrivalDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.arrivalDate],
        MMEEventKeyDepartureDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.departureDate]};

    [self pushEvent:[MMEEvent visitEventWithAttributes:eventAttributes]];

    if ([self.delegate respondsToSelector:@selector(eventsManager:didVisit:)]) {
        [self.delegate eventsManager:self didVisit:visit];
    }
}

@end

NS_ASSUME_NONNULL_END
