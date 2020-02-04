#import <XCTest/XCTest.h>

#import "MMEEventsManager.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"
#import "MMEUIApplicationWrapper.h"

#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"

#import "MMEAPIClientFake.h"
#import "MMETimerManagerFake.h"
#import "MMELocationManagerFake.h"
#import "MMEUIApplicationWrapperFake.h"


@interface MMEEventsManager (Tests)

@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) MMETimerManager *timerManager;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (instancetype)initShared;
- (void)pushEvent:(MMEEvent *)event;
- (void)processAuthorizationStatus:(CLAuthorizationStatus)authStatus andApplicationState:(UIApplicationState)applicationState;
- (void)powerStateDidChange:(NSNotification *)notification;
- (void)updateNextTurnstileSendDate;
- (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled;
- (BOOL)isDebugLoggingEnabled;
- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations;

@end

@interface MMEEventsManagerTests : XCTestCase
@property (nonatomic) MMEEventsManager *eventsManager;

@end

@implementation MMEEventsManagerTests

- (void)setUp {
    self.eventsManager = [MMEEventsManager.alloc initShared];
    self.eventsManager.application = [[MMEUIApplicationWrapperFake alloc] init];
    
    MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
    commonEventData.vendorId = @"vendor-id";
    commonEventData.model = @"model";
    commonEventData.osVersion = @"ios-version";
    self.eventsManager.commonEventData = commonEventData;
    
    [NSUserDefaults.mme_configuration mme_registerDefaults];
    [NSUserDefaults.mme_configuration mme_setAccessToken:@"access-token"];
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:YES];
}

- (void)tearDown {
    [NSUserDefaults mme_resetConfiguration];
}

- (void)testPausesWithWhenInUseAuthAndBackgrounded {
    self.eventsManager.paused = NO;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateBackground];
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testUnpausesWithWhenInUseAuthAndAppActive {
    self.eventsManager.paused = YES;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateActive];
    XCTAssert(self.eventsManager.paused == NO);
}

- (void)testUnpausesWithAlwaysAuthAndBackgrounded {
    self.eventsManager.paused = YES;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateBackground];
    XCTAssert(self.eventsManager.paused == NO);
}

- (void)testUnpausesWithAlwaysAuthAndAppActive {
    self.eventsManager.paused = YES;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    XCTAssert(self.eventsManager.paused == NO);
}

- (void)testRemainsPausedWithDeniedAuthAndAppActive {
    self.eventsManager.paused = YES;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusDenied andApplicationState:UIApplicationStateActive];
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testRemainsPausedWithRestrictedAuthAndAppActive {
    self.eventsManager.paused = YES;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusRestricted andApplicationState:UIApplicationStateActive];
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testRemainsPausedWithNotDeterminedAuthAndAppActive {
    self.eventsManager.paused = YES;
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusNotDetermined andApplicationState:UIApplicationStateActive];
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testEventQueuedAndFlushed {
    self.eventsManager.paused = NO;
    [self.eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    [self.eventsManager pauseOrResumeMetricsCollectionIfRequired];
    XCTAssert(self.eventsManager.eventQueue.count == 0);
    XCTAssert(self.eventsManager.paused = YES);
}

- (void)testEventsManagerReinitialized {
    MMEEventsManager *capturedEventsManager = self.eventsManager;
    [self.eventsManager initializeWithAccessToken:@"access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"sdk-version"];
    
    XCTAssert([self.eventsManager isEqual:capturedEventsManager]);
}

- (void)testEventCountThresholdReached {
    self.eventsManager.paused = NO;
    
    [NSUserDefaults.mme_configuration setObject:@2 forKey:MMEEventFlushCount];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    
    MMEMapboxEventAttributes *eventAttributes = @{
                            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
    };
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:self.eventsManager.commonEventData];
                            
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testTimerReachedWithEventQueued {
    self.eventsManager.paused = NO;
    
    MMETimerManagerFake *timerManager = [[MMETimerManagerFake alloc] init];
    timerManager.target = self.eventsManager;
    timerManager.selector = @selector(flush);
    self.eventsManager.timerManager = timerManager;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    
    MMEMapboxEventAttributes *eventAttributes = @{
                            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
    };
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:self.eventsManager.commonEventData];
    
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    
    [timerManager triggerTimer];
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testCollectionNotEnabledWhilePausedAndAlwaysAuth {
    self.eventsManager.paused = YES;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhileNOTPausedAndAlwaysAuth {
    self.eventsManager.paused = NO;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhilePausedAndAlwaysAuthAndBackgrounded {
    self.eventsManager.paused = YES;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateBackground];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhileNOTPausedAndAlwaysAuthAndBackgrounded {
    self.eventsManager.paused = NO;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateBackground];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhilePausedAndWhenInUseAuth {
    self.eventsManager.paused = YES;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateActive];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhileNOTPausedAndWhenInUseAuth {
    self.eventsManager.paused = NO;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateActive];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhilePausedAndWhenInUseAuthAndBackgrounded {
    self.eventsManager.paused = YES;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateBackground];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testCollectionNotEnabledWhileNOTPausedAndWhenInUseAuthAndBackgrounded {
    self.eventsManager.paused = NO;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateBackground];
    
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testEventsFlushWhenCollectionIsDisabled {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    
    MMEMapboxEventAttributes *eventAttributes = @{
                            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
    };
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:self.eventsManager.commonEventData];
    
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    
    self.eventsManager.paused = NO;
    
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:NO];
    
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    XCTAssert(self.eventsManager.paused == YES);
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testPauseOrResumeFlushInBackground {
    self.eventsManager.paused = NO;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    
    MMEMapboxEventAttributes *eventAttributes = @{
                            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
    };
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:self.eventsManager.commonEventData];
    
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    
    MMEUIApplicationWrapperFake *fakeApplicationWrapper = (MMEUIApplicationWrapperFake*)self.eventsManager.application;
    fakeApplicationWrapper.applicationState = UIApplicationStateBackground;
    
    [self.eventsManager pauseOrResumeMetricsCollectionIfRequired];
    XCTAssert(self.eventsManager.paused == YES);
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}
 
- (void)testSendsTurnstileWhenCollectionDisabled {
    XCTAssert(self.eventsManager.nextTurnstileSendDate == nil);

    NSUserDefaults.mme_configuration.mme_isCollectionEnabled = NO; // on device or in simulator
    
    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
    
    NSUserDefaults.mme_configuration.mme_accessToken = @"access-token";
    NSUserDefaults.mme_configuration.mme_legacyUserAgentBase = @"user-agent-base";
    NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion = @"host-sdk-version";
    
    self.eventsManager.apiClient = fakeAPIClient;
    
    self.eventsManager.nextTurnstileSendDate = MMEDate.distantPast;
    
    [self.eventsManager sendTurnstileEvent];
    
    XCTAssert([(MMETestStub*)self.eventsManager.apiClient received:@selector(postEvent:completionHandler:)]);
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testSendsTurnstileWhenCollectionEnabled {
    XCTAssert(self.eventsManager.nextTurnstileSendDate == nil);

    NSUserDefaults.mme_configuration.mme_isCollectionEnabled = YES; // on device or in simulator
    
    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
    
    NSUserDefaults.mme_configuration.mme_accessToken = @"access-token";
    NSUserDefaults.mme_configuration.mme_legacyUserAgentBase = @"user-agent-base";
    NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion = @"host-sdk-version";
    
    self.eventsManager.apiClient = fakeAPIClient;
    
    self.eventsManager.nextTurnstileSendDate = MMEDate.distantPast;
    
    [self.eventsManager sendTurnstileEvent];
    
    XCTAssert([(MMETestStub*)self.eventsManager.apiClient received:@selector(postEvent:completionHandler:)]);
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testDoesNotSendTurnstileWithFutureSendDateAndCollectionEnabled {
    XCTAssert(self.eventsManager.nextTurnstileSendDate == nil);

    NSUserDefaults.mme_configuration.mme_isCollectionEnabled = YES; // on device or in simulator
    
    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
    
    NSUserDefaults.mme_configuration.mme_accessToken = @"access-token";
    NSUserDefaults.mme_configuration.mme_legacyUserAgentBase = @"user-agent-base";
    NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion = @"host-sdk-version";
    
    self.eventsManager.apiClient = fakeAPIClient;
    
    self.eventsManager.nextTurnstileSendDate = MMEDate.distantFuture;
    
    [self.eventsManager sendTurnstileEvent];
    
    XCTAssertFalse([(MMETestStub*)self.eventsManager.apiClient received:@selector(postEvent:completionHandler:)]);
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testDisableLocationMetrics {
    NSUserDefaults.mme_configuration.mme_isCollectionEnabled = YES;
    
    [self.eventsManager disableLocationMetrics];
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
}

- (void)testLowPowerMode {
    XCTestExpectation *lowPowerCompletionExpectation = [self expectationWithDescription:@"It should flush and pause"];
    [NSUserDefaults.mme_configuration mme_setIsCollectionEnabled:YES];
    self.eventsManager.paused = NO;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:0.001 longitude:0.001];
    
    [self.eventsManager locationManager:self.eventsManager.locationManager didUpdateLocations:@[location, location2]];
    XCTAssert(self.eventsManager.eventQueue.count == 2);

    //simulating low power mode
    [self.eventsManager powerStateDidChange:nil];
    
    //waiting a bit
    dispatch_async(dispatch_get_main_queue(), ^{
        [lowPowerCompletionExpectation fulfill];
    });

    [self waitForExpectations:@[lowPowerCompletionExpectation] timeout:1];

    XCTAssert(self.eventsManager.eventQueue.count == 0);
    XCTAssert(self.eventsManager.paused == YES);
}

- (void)testQueueLocationEvents {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:0.001 longitude:0.001];
    
    [self.eventsManager locationManager:self.eventsManager.locationManager didUpdateLocations:@[location, location2]];
    XCTAssert(self.eventsManager.eventQueue.count == 2);
}



#pragma mark - Internal API

- (void)testPushEventNil {
    [self.eventsManager pushEvent:nil];
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testNextTurnstileDate {
    NSDate *capturedDate = self.eventsManager.nextTurnstileSendDate;
    [self.eventsManager updateNextTurnstileSendDate];
    XCTAssert(capturedDate != self.eventsManager.nextTurnstileSendDate);
}



@end
