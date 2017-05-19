#import "MMEEventsManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"
#import "MMEConstants.h"
#import "MMEAPIClient.h"

#import "NSDateFormatter+MMEMobileEvents.h"
#import "CLLocation+MMEMobileEvents.h"

@interface MMEEventsManager () <MMELocationManagerDelegate>

@property (nonatomic) MMELocationManager *locationManager;
@property (nonatomic) MMEAPIClient *apiClient;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MGLMapboxEventAttributes *) *eventQueue;
@property (nonatomic) MMEUniqueIdentifier *uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) NSDateFormatter *rfc3339DateFormatter;

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

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase {
    _apiClient = [[MMEAPIClient alloc] initWithAccessToken:accessToken userAgentBase:userAgentBase];
//    _locationManager = [[MMELocationManager alloc] init];
//    _locationManager.delegate = self;
}

- (void)sendTurnstileEvent {
    if (!self.commonEventData.vendorId) {
        NSLog(@"================> no vendor id available, cannot can't send turntile event");
        return;
    }
    
    if (!self.apiClient.userAgentBase) {
        NSLog(@"================> no user agent base set, cannot can't send turntile event");
        return;
    }
    
    if (!self.apiClient.accessToken) {
        NSLog(@"================> no access token sent, cannot can't send turntile event");
        return;
    }
    
    NSDictionary *turnstileEventAttributes = @{MMEEventKeyEvent: MMEEventTypeAppUserTurnstile,
                                               MMEEventKeyCreated: [self.rfc3339DateFormatter stringFromDate:[NSDate date]],
                                               MMEEventKeyVendorID: self.commonEventData.vendorId,
                                               MMEEventKeyEnabledTelemetry: @([self isTelemetryDisabled])};
    
    [self.apiClient postEvent:[MMEEvent turnstileEventWithAttributes:turnstileEventAttributes] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"================> could not send turnstile event: %@", error);
            return;
        }
        
        NSLog(@"================> sent turnstile event with attributes: %@", turnstileEventAttributes);
    }];
}

- (void)pushEvent:(MMEEvent *)event {
    // TODO: nil event check

    // TODO: send turnstile as side effect of map load

    // TODO: don't send if paused

    // TODO: handle all event types
    [self.eventQueue addObject:event.attributes];

    // TODO: flush if required
    // TODO: if the first event then start the flush timer
    // TODO: log if unknown event
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
