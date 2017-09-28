#import "MMEEventsManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"
#import "MMEConstants.h"
#import "MMEAPIClient.h"
#import "MMEEventLogger.h"
#import "MMEEventsConfiguration.h"
#import "MMETimerManager.h"
#import "MMEUIApplicationWrapper.h"
#import "MMENSDateWrapper.h"
#import "MMECategoryLoader.h"

#import "CLLocation+MMEMobileEvents.h"

@interface MMEEventsManager () <MMELocationManagerDelegate>

@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) id<MMECLLocationManagerWrapper> locationManagerWrapper;
@property (nonatomic) id<MMEAPIClient> apiClient;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) MMEEventsConfiguration *configuration;
@property (nonatomic) MMETimerManager *timerManager;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) MMENSDateWrapper *dateWrapper;
@property (nonatomic, getter=isLocationMetricsEnabled) BOOL locationMetricsEnabled;

@end

@implementation MMEEventsManager {
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}

+ (instancetype)sharedManager {
    static MMEEventsManager *_sharedManager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        [MMECategoryLoader loadCategories];
        _sharedManager = [[MMEEventsManager alloc] init];
    });

    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _metricsEnabled = YES;
        _locationMetricsEnabled = YES;
        _accountType = 0;
        _eventQueue = [NSMutableArray array];
        _commonEventData = [[MMECommonEventData alloc] init];
        _configuration = [MMEEventsConfiguration defaultEventsConfiguration];
        _uniqueIdentifer = [[MMEUniqueIdentifier alloc] initWithTimeInterval:_configuration.instanceIdentifierRotationTimeInterval];
        _application = [[MMEUIApplicationWrapper alloc] init];
        _locationManagerWrapper = [[MMECLLocationManagerWrapper alloc] init];
        _dateWrapper = [[MMENSDateWrapper alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self pauseMetricsCollection];
}

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion {    
    self.apiClient = [[MMEAPIClient alloc] initWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseOrResumeMetricsCollectionIfRequired) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseOrResumeMetricsCollectionIfRequired) name:UIApplicationDidBecomeActiveNotification object:nil];
    if (&NSProcessInfoPowerStateDidChangeNotification != NULL) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseOrResumeMetricsCollectionIfRequired) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    }
    
    self.paused = YES;
    
    self.locationManager = [[MMELocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.metricsEnabledForInUsePermissions = self.metricsEnabledForInUsePermissions;
    [self resumeMetricsCollection];
    
    self.timerManager = [[MMETimerManager alloc] initWithTimeInterval:self.configuration.eventFlushSecondsThreshold target:self selector:@selector(flush)];
}

# pragma mark - Public API

- (NSString *)accessToken {
    return self.apiClient.accessToken;
}

- (NSString *)userAgentBase {
    return self.apiClient.userAgentBase;
}

- (NSString *)hostSDKVersion {
    return self.apiClient.hostSDKVersion;
}

- (void)setMetricsEnabledForInUsePermissions:(BOOL)metricsEnabledForInUsePermissions {
    _metricsEnabledForInUsePermissions = metricsEnabledForInUsePermissions;
    self.locationManager.metricsEnabledForInUsePermissions = metricsEnabledForInUsePermissions;
}

- (void)disableLocationMetrics {
    self.locationMetricsEnabled = NO;
    [self.locationManager stopUpdatingLocation];
}

- (void)pauseOrResumeMetricsCollectionIfRequired {
    // Prevent blue status bar when host app has `when in use` permission only and it is not in foreground
    if ([self.locationManagerWrapper authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse &&
        self.application.applicationState == UIApplicationStateBackground &&
        !self.isMetricsEnabledForInUsePermissions) {
        if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            _backgroundTaskIdentifier = [self.application beginBackgroundTaskWithExpirationHandler:^{
                [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Ending background task",
                                                     @"Identifier": @(_backgroundTaskIdentifier)}];
                [self.application endBackgroundTask:_backgroundTaskIdentifier];
                _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }];
            [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Initiated background task",
                                                 @"Identifier": @(_backgroundTaskIdentifier)}];
            [self flush];
        }
        [self pauseMetricsCollection];
        return;
    }
    
    // Toggle pause based on current pause state, user opt-out state, and low-power state.
    if (self.paused && [self isEnabled]) {
        [self resumeMetricsCollection];
    } else if (!self.paused && ![self isEnabled]) {
        [self flush];
        [self pauseMetricsCollection];
    }
}

- (void)flush {
    if (self.paused) {
        return;
    }
    
    if (self.apiClient.accessToken == nil) {
        return;
    }
    
    if (self.eventQueue.count == 0) {
        return;
    }
    
    NSArray *events = [self.eventQueue copy];
    __weak __typeof__(self) weakSelf = self;
    [self.apiClient postEvents:events completionHandler:^(NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (error) {
            [strongSelf pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Network error",
                                                       @"error": error}];
        } else {
            [strongSelf pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"post",
                                                       @"debug.eventsCount": @(events.count)}];
        }
        
        
        if (_backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Ending background task",
                                                 @"Identifier": @(_backgroundTaskIdentifier)}];
            [self.application endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    [self.eventQueue removeAllObjects];
    [self.timerManager cancel];
    
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription:@"flush"}];
}

- (void)sendTurnstileEvent {
    if (self.nextTurnstileSendDate && [[self.dateWrapper date] timeIntervalSinceDate:self.nextTurnstileSendDate] < 0) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Turnstile event already sent; waiting until %@ to send another one"}];
        return;
    }
    
    if (!self.apiClient.accessToken) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No access token sent, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.commonEventData.vendorId) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No vendor id available, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.commonEventData.model) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No model available, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.commonEventData.iOSVersion) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No iOS version available, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.apiClient.userAgentBase) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No user agent base set, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.apiClient.hostSDKVersion) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No host SDK version set, cannot can't send turntile event"}];
        return;
    }
    
    NSDictionary *turnstileEventAttributes = @{MMEEventKeyEvent: MMEEventTypeAppUserTurnstile,
                                               MMEEventKeyCreated: [self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]],
                                               MMEEventKeyVendorID: self.commonEventData.vendorId,
                                               // MMEEventKeyDevice is synonomous with MMEEventKeyModel but the server will only accept "device" in turnstile events
                                               MMEEventKeyDevice: self.commonEventData.model,
                                               MMEEventKeyOperatingSystem: self.commonEventData.iOSVersion,
                                               MMEEventSDKIdentifier: self.apiClient.userAgentBase,
                                               MMEEventSDKVersion: self.apiClient.hostSDKVersion,
                                               MMEEventKeyEnabledTelemetry: @([self isEnabled])};
    
    MMEEvent *turnstileEvent = [MMEEvent turnstileEventWithAttributes:turnstileEventAttributes];
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Sending turnstile event: %@", turnstileEvent]}];
    
    __weak __typeof__(self) weakSelf = self;
    [self.apiClient postEvent:turnstileEvent completionHandler:^(NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (error) {
            [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Could not send turnstile event: %@", error]}];
            return;
        }
        
        [strongSelf updateNextTurnstileSendDate];
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Sent turnstile event"}];
    }];
}

- (void)enqueueEventWithName:(NSString *)name {
    [self createAndPushEventBasedOnName:name attributes:nil];
}

- (void)enqueueEventWithName:(NSString *)name attributes:(MMEMapboxEventAttributes *)attributes {
    [self createAndPushEventBasedOnName:name attributes:attributes];
}

- (void)createAndPushEventBasedOnName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *event = nil;
    if ([name isEqualToString:MMEEventTypeMapLoad]) {
        event = [MMEEvent mapLoadEventWithDateString:[self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]]
                                     commonEventData:self.commonEventData];
    } else if ([name isEqualToString:MMEEventTypeMapTap]) {
        event = [MMEEvent mapTapEventWithDateString:[self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]]
                                         attributes:attributes];
    } else if ([name isEqualToString:MMEEventTypeMapDragEnd]) {
        event = [MMEEvent mapDragEndEventWithDateString:[self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]]
                                             attributes:attributes];
    }
    
    if ([name hasPrefix:MMENavigationEventPrefix]) {
        event = [MMEEvent navigationEventWithName:name attributes:attributes];
    }
    
    if (event) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Pushing event: %@", event]}];
        [self pushEvent:event];
    } else {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Unknown event: %@", event]}];
    }
}

- (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled {
    [[MMEEventLogger class] setEnabled:debugLoggingEnabled];
}

- (BOOL)isDebugLoggingEnabled {
    return [[MMEEventLogger class] isEnabled];
}

#pragma mark - Internal API

- (BOOL)isEnabled {
#if TARGET_OS_SIMULATOR
    return self.isMetricsEnabled && self.accountType == 0 && self.metricsEnabledInSimulator;
#else
    if ([NSProcessInfo instancesRespondToSelector:@selector(isLowPowerModeEnabled)]) {
        return ![[NSProcessInfo processInfo] isLowPowerModeEnabled];
    }
    return self.isMetricsEnabled && self.accountType == 0;
#endif
}

- (void)pauseMetricsCollection {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Pausing metrics collection..."}];
    if (self.isPaused) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Already paused"}];
        return;
    }
    
    self.paused = YES;
    [self.timerManager cancel];
    [self.eventQueue removeAllObjects];
    
    [self.locationManager stopUpdatingLocation];
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Paused and location manager stopped"}];
}

- (void)resumeMetricsCollection {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Resuming metrics collection..."}];
    if (!self.isPaused || ![self isEnabled]) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Already running"}];
        return;
    }
    
    self.paused = NO;
    
    if (self.locationMetricsEnabled) {
        [self.locationManager startUpdatingLocation];
    }
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Resumed and location manager started"}];
}

- (void)updateNextTurnstileSendDate {
    // Find the time a day from now (sometime tomorrow)
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    NSDate *sometimeTomorrow = [calendar dateByAddingComponents:dayComponent toDate:[self.dateWrapper date] options:0];
    
    // Find the start of tomorrow and use that as the next turnstile send date. The effect of this is that
    // turnstile events can be sent as much as once per calendar day and always at the start of a session
    // when a map load happens.
    NSDate *startOfTomorrow = nil;
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&startOfTomorrow interval:nil forDate:sometimeTomorrow];
    self.nextTurnstileSendDate = startOfTomorrow;
    
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Set next turnstile date to: %@", self.nextTurnstileSendDate]}];
}

- (void)pushEvent:(MMEEvent *)event {
    if (!event) {
        return;
    }
    
    if (self.paused) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Aborting pushing event because collection is paused."}];
        return;
    }
    
    [self.eventQueue addObject:event];
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Added event to event queue; event queue now has %ld events", (long)self.eventQueue.count]}];
    
    if (self.eventQueue.count >= self.configuration.eventFlushCountThreshold) {
        [self flush];
    }
    
    if (self.eventQueue.count == 1) {
        [self.timerManager start];
    }
}

- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes {
    MMEMutableMapboxEventAttributes *combinedAttributes = [MMEMutableMapboxEventAttributes dictionaryWithDictionary:attributes];
    [combinedAttributes setObject:[self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]] forKey:@"created"];
    [combinedAttributes setObject:self.uniqueIdentifer.rollingInstanceIdentifer forKey:@"instance"];
    MMEEvent *debugEvent = [MMEEvent debugEventWithAttributes:combinedAttributes];
    [MMEEventLogger logEvent:debugEvent];
}

#pragma mark - MMELocationManagerDelegate

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Location manager sent %ld locations", (long)locations.count]}];
    
    for (CLLocation *location in locations) {        
        MMEMapboxEventAttributes *eventAttributes = @{MMEEventKeyCreated: [self.dateWrapper formattedDateStringForDate:[location timestamp]],
                                                      MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                                                      MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                                                      MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                                                      MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])};
        [self pushEvent:[MMEEvent locationEventWithAttributes:eventAttributes
                                            instanceIdentifer:self.uniqueIdentifer.rollingInstanceIdentifer
                                              commonEventData:self.commonEventData]];
    }
}

- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Location manager started location updates"}];
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Location manager timed out"}];
}

- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Location manager automatically paused"}];
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Location manager stopped location updates"}];
}

@end
