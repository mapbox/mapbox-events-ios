#import "MMEEventsManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"
#import "MMEConstants.h"
#import "MMEAPIClient.h"
#import "MMEEventLogger.h"

#import "NSDateFormatter+MMEMobileEvents.h"
#import "CLLocation+MMEMobileEvents.h"

@interface MMEEventsManager () <MMELocationManagerDelegate>

@property (nonatomic) MMELocationManager *locationManager;
@property (nonatomic) id<MMEAPIClient> apiClient;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MGLMapboxEventAttributes *) *eventQueue;
@property (nonatomic) MMEUniqueIdentifier *uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) NSDateFormatter *rfc3339DateFormatter;
@property (nonatomic) NSDate *nextTurnstileSendDate;

@end

@implementation MMEEventsManager

+ (nullable instancetype)sharedManager {
//    if (NSProcessInfo.processInfo.mgl_isInterfaceBuilderDesignablesAgent) {
//        return nil;
//    }

    static MMEEventsManager *_sharedManager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedManager = [[MMEEventsManager alloc] init];
    });

    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eventQueue = [NSMutableArray array];
        _uniqueIdentifer = [[MMEUniqueIdentifier alloc] init];
        _commonEventData = [[MMECommonEventData alloc] init];
        _rfc3339DateFormatter = [NSDateFormatter rfc3339DateFormatter];
    }
    return self;
}

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion {
    _apiClient = [[MMEAPIClient alloc] initWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    
    _locationManager = [[MMELocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void)sendTurnstileEvent {
    if (self.nextTurnstileSendDate && [[NSDate date] timeIntervalSinceDate:self.nextTurnstileSendDate] < 0) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Turnstile event already sent; waiting until %@ to send another one"}];
        return;
    }
    
    if (!self.commonEventData.vendorId) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No vendor id available, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.apiClient.userAgentBase) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No user agent base set, cannot can't send turntile event"}];
        return;
    }
    
    if (!self.apiClient.accessToken) {
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"No access token sent, cannot can't send turntile event"}];
        return;
    }
    
    NSDictionary *turnstileEventAttributes = @{MMEEventKeyEvent: MMEEventTypeAppUserTurnstile,
                                               MMEEventKeyCreated: [self.rfc3339DateFormatter stringFromDate:[NSDate date]],
                                               MMEEventKeyVendorID: self.commonEventData.vendorId,
                                               MMEEventKeyEnabledTelemetry: @([self isTelemetryDisabled])};
    
    __weak __typeof__(self) weakSelf = self;
    [self.apiClient postEvent:[MMEEvent turnstileEventWithAttributes:turnstileEventAttributes] completionHandler:^(NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (error) {
            [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: [NSString stringWithFormat:@"Could not send turnstile event: %@", error]}];
            return;
        }
        
        [strongSelf updateNextTurnstileSendDate];
        [self pushDebugEventWithAttributes:@{MMEEventKeyLocalDebugDescription: @"Sent turnstile event"}];
    }];
}

- (void)updateNextTurnstileSendDate {
    // Find the time a day from now (sometime tomorrow)
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    NSDate *sometimeTomorrow = [calendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
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
    
    // TODO: don't send if paused
    
    // TODO: handle all event types
    [self.eventQueue addObject:event.attributes];
    
    // TODO: flush if required
    // TODO: if the first event then start the flush timer
    // TODO: log if unknown event
}

- (void)pushDebugEventWithAttributes:(MGLMapboxEventAttributes *)attributes {
    MGLMutableMapboxEventAttributes *combinedAttributes = [MGLMutableMapboxEventAttributes dictionaryWithDictionary:attributes];
    [combinedAttributes setObject:[self.rfc3339DateFormatter stringFromDate:[NSDate date]] forKey:@"created"];
//    [combinedAttributes setObject:self.uniqueIdentifer.rollingInstanceIdentifer forKey:@"instance"];
    MMEEvent *debugEvent = [MMEEvent debugEventWithAttributes:combinedAttributes];
    [MMEEventLogger logEvent:debugEvent];
}

#pragma mark - MMELocationManagerDelegate

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
    
    for (CLLocation *location in locations) {
        MGLMapboxEventAttributes *eventAttributes = @{MMEEventKeyCreated: [self.rfc3339DateFormatter stringFromDate:location.timestamp],
                                                      MMEEventKeyLatitude: @([location latitudeRoundedWithPrecision:7]),
                                                      MMEEventKeyLongitude: @([location longitudeRoundedWithPrecision:7]),
                                                      MMEEventKeyAltitude: @([location roundedAltitude]),
                                                      MMEEventHorizontalAccuracy: @([location roundedHorizontalAccuracy])};
        [self pushEvent:[MMEEvent locationEventWithAttributes:eventAttributes
                                            instanceIdentifer:self.uniqueIdentifer.rollingInstanceIdentifer
                                              commonEventData:self.commonEventData]];
    }
}

- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

@end
