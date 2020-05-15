#import <XCTest/XCTest.h>

#import "MMEEventsManager.h"
#import "MMEEventsManager_Private.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEUniqueIdentifier.h"
#import "MMEUIApplicationWrapper.h"

#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"

#import "MMEAPIClientFake.h"
#import "MMELocationManagerFake.h"
#import "MMEUIApplicationWrapperFake.h"
#import "MMEPreferences.h"
#import "MMELogger.h"
#import "MMEMetricsManager.h"
#import "MMEDispatchManager.h"
#import "MMEEventsManager_Private.h"
#import "MMEBundleInfoFake.h"


@interface MMEEventsManager (Tests)

@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (void)pushEvent:(MMEEvent *)event;
- (void)processAuthorizationStatus:(CLAuthorizationStatus)authStatus andApplicationState:(UIApplicationState)applicationState;
- (void)powerStateDidChange:(NSNotification *)notification;
- (void)updateNextTurnstileSendDate;
- (void)setDebugLoggingEnabled:(BOOL)debugLoggingEnabled;
- (BOOL)isDebugLoggingEnabled;
- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations;

@end

@interface MMEPreferences (Tests)
-(void)setEventFlushCount:(NSUInteger)eventFlushCount;
@end

@interface MMEEventsManagerTests : XCTestCase
@property (nonatomic, strong) MMEPreferences* preferences;
@property (nonatomic, strong) MMEEventsManager* eventsManager;

@end

@implementation MMEEventsManagerTests

- (void)setUp {

    MMELogger* logger = [[MMELogger alloc] init];
    self.preferences = [[MMEPreferences alloc] initWithBundle:[MMEBundleInfoFake new]
                                                    dataStore:NSUserDefaults.mme_configuration];

    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithLogger:logger config:self.preferences];


    self.preferences.accessToken = @"access-token";
    self.preferences.isCollectionEnabled = YES;

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                            application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                       dispatchManager:[[MMEDispatchManager alloc] init]
                                                                logger:logger];

}

- (void)tearDown {

}

- (void)testAccessTokenSetter {
    self.preferences.accessToken = @"Foo";
    XCTAssertEqualObjects(self.preferences.accessToken, @"Foo");

    self.preferences.accessToken = @"Bar";
    XCTAssertEqualObjects(self.preferences.accessToken, @"Bar");
}

- (void)testIsCollectionEnabledDefault {
    self.preferences.isCollectionEnabled = YES;
}

- (void)testIsCollectionSetter {
    self.preferences.isCollectionEnabled = NO;
    XCTAssertEqual(self.preferences.isCollectionEnabled, NO);

    self.preferences.isCollectionEnabled = YES;
    XCTAssertEqual(self.preferences.isCollectionEnabled, YES);
}

- (void)testIsCollectionEnabledInBackgroundSetter {
    self.preferences.isCollectionEnabled = YES;
    self.preferences.isCollectionEnabledInBackground = NO;
    XCTAssertEqual(self.preferences.isCollectionEnabledInBackground, NO);

    self.preferences.isCollectionEnabledInBackground = YES;
    XCTAssertEqual(self.preferences.isCollectionEnabledInBackground, YES);
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

    [self.preferences setEventFlushCount:2];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    
    MMEMapboxEventAttributes *eventAttributes = @{
                            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
    };
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:nil];
                            
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);

    [self.eventsManager pushEvent:locationEvent];
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
}

- (void)testTimerReachedWithEventQueued {
    self.eventsManager.paused = NO;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    MMEMapboxEventAttributes *eventAttributes = @{
                            MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                            MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                            MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                            MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                            MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
    };
    
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:nil];
    
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
}

- (void)testCollectionNotEnabledWhilePausedAndAlwaysAuth {
    self.eventsManager.paused = YES;

    self.preferences.isCollectionEnabled = NO;

    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];

    XCTAssertTrue(self.eventsManager.paused);
}



- (void)testCollectionNotEnabledWhileNOTPausedAndAlwaysAuth {
    self.eventsManager.paused = NO;

    self.preferences.isCollectionEnabled = NO;
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    
    XCTAssertTrue(self.eventsManager.paused);
}

- (void)testCollectionNotEnabledWhilePausedAndAlwaysAuthAndBackgrounded {
    self.eventsManager.paused = YES;

    self.preferences.isCollectionEnabled = NO;
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateBackground];
    
    XCTAssertTrue(self.eventsManager.paused);
}

// Dane - results in backgroundCollection Off
- (void)testCollectionNotEnabledWhileNOTPausedAndAlwaysAuthAndBackgrounded {
    self.eventsManager.paused = NO;
    
    self.preferences.isCollectionEnabled = NO;
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateBackground];
    
    XCTAssertTrue(self.eventsManager.paused);
}

- (void)testCollectionNotEnabledWhilePausedAndWhenInUseAuth {
    self.eventsManager.paused = YES;
    
    self.preferences.isCollectionEnabled = NO;

    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateActive];
    
    XCTAssertTrue(self.eventsManager.paused);
}

- (void)testCollectionNotEnabledWhileNOTPausedAndWhenInUseAuth {
    self.eventsManager.paused = NO;
    
    self.preferences.isCollectionEnabled = NO;
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateActive];
    
    XCTAssertTrue(self.eventsManager.paused);
}

- (void)testCollectionNotEnabledWhilePausedAndWhenInUseAuthAndBackgrounded {
    self.eventsManager.paused = YES;
    
    self.preferences.isCollectionEnabled = NO;
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateBackground];
    
    XCTAssertTrue(self.eventsManager.paused);
}

- (void)testCollectionNotEnabledWhileNOTPausedAndWhenInUseAuthAndBackgrounded {
    self.eventsManager.paused = NO;
    
    self.preferences.isCollectionEnabled = NO;
    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse andApplicationState:UIApplicationStateBackground];
    
    XCTAssertTrue(self.eventsManager.paused);
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
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:nil];
    
    [self.eventsManager pushEvent:locationEvent];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    
    self.eventsManager.paused = NO;
    
    self.preferences.isCollectionEnabled = NO;

    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    XCTAssertTrue(self.eventsManager.paused);
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
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
    MMEEvent *locationEvent = [MMEEvent locationEventWithAttributes:eventAttributes instanceIdentifer:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer commonEventData:nil];
    
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

    self.preferences.isCollectionEnabled = NO; // on device or in simulator
    self.preferences.accessToken = @"access-token";
    self.preferences.legacyUserAgentBase = @"user-agent-base";
    self.preferences.legacyHostSDKVersion = @"host-sdk-version";

    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];

    self.eventsManager.apiClient = fakeAPIClient;
    
    self.eventsManager.nextTurnstileSendDate = MMEDate.distantPast;
    
    [self.eventsManager sendTurnstileEvent];
    
    XCTAssert([(MMETestStub*)self.eventsManager.apiClient received:@selector(postEvent:completionHandler:)]);
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testSendsTurnstileWhenCollectionEnabled {
    XCTAssert(self.eventsManager.nextTurnstileSendDate == nil);

    self.preferences.isCollectionEnabled = YES; // on device or in simulator
    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];

    self.preferences.accessToken = @"access-token";
    self.preferences.legacyUserAgentBase = @"user-agent-base";
    self.preferences.legacyHostSDKVersion = @"host-sdk-version";
    
    self.eventsManager.apiClient = fakeAPIClient;
    
    self.eventsManager.nextTurnstileSendDate = MMEDate.distantPast;
    
    [self.eventsManager sendTurnstileEvent];
    
    XCTAssert([(MMETestStub*)self.eventsManager.apiClient received:@selector(postEvent:completionHandler:)]);
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
}

- (void)testDoesNotSendTurnstileWithFutureSendDateAndCollectionEnabled {
    XCTAssert(self.eventsManager.nextTurnstileSendDate == nil);

    self.preferences.isCollectionEnabled = YES; // on device or in simulator

    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];

    self.preferences.accessToken = @"access-token";
    self.preferences.legacyUserAgentBase = @"user-agent-base";
    self.preferences.legacyHostSDKVersion = @"host-sdk-version";
    
    self.eventsManager.apiClient = fakeAPIClient;
    
    self.eventsManager.nextTurnstileSendDate = MMEDate.distantFuture;
    
    [self.eventsManager sendTurnstileEvent];
    
    XCTAssertFalse([(MMETestStub*)self.eventsManager.apiClient received:@selector(postEvent:completionHandler:)]);
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
}

- (void)testDisableLocationMetrics {
    self.preferences.isCollectionEnabled = YES;

    [self.eventsManager disableLocationMetrics];
    XCTAssertFalse(self.preferences.isCollectionEnabled);
}

- (void)testLowPowerMode {
    XCTestExpectation *lowPowerCompletionExpectation = [self expectationWithDescription:@"It should flush and pause"];

    // If enabled and paused, it appears as though that kicks off the flow again?
    self.preferences.isCollectionEnabled = YES;
    self.eventsManager.paused = NO;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:0.001 longitude:0.001];

    [self.eventsManager locationManager:self.eventsManager.locationManager didUpdateLocations:@[location, location2]];
    XCTAssertEqual(self.eventsManager.eventQueue.count, 2);

    //simulating low power mode
    [self.eventsManager powerStateDidChange:nil];
    
    //waiting a bit
    dispatch_async(dispatch_get_main_queue(), ^{
        [lowPowerCompletionExpectation fulfill];
    });

    [self waitForExpectations:@[lowPowerCompletionExpectation] timeout:1];

    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
    XCTAssertTrue(self.eventsManager.paused);
}

- (void)testQueueLocationEvents {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:0.001 longitude:0.001];
    
    [self.eventsManager locationManager:self.eventsManager.locationManager didUpdateLocations:@[location, location2]];
    XCTAssertEqual(self.eventsManager.eventQueue.count, 2);
}



// MARK: - Internal API

- (void)testPushEventNil {
    [self.eventsManager pushEvent:nil];
    XCTAssert(self.eventsManager.eventQueue.count == 0);
}

- (void)testNextTurnstileDate {
    NSDate *capturedDate = self.eventsManager.nextTurnstileSendDate;
    [self.eventsManager updateNextTurnstileSendDate];
    XCTAssert(capturedDate != self.eventsManager.nextTurnstileSendDate);
}


// Each Initialized EventManager should be different unless using shared
-(void)testEventManagerInitShouldBeDifferent {
    MMEEventsManager* eventManager1 = [[MMEEventsManager alloc] initWithDefaults];
    MMEEventsManager* eventManager2 = [[MMEEventsManager alloc] initWithDefaults];
    XCTAssertNotEqual(eventManager1, eventManager2);
}

-(void)testSharedEventManagerIsTheSame {
    XCTAssertEqual(MMEEventsManager.sharedManager, MMEEventsManager.sharedManager);
}

-(void)testStartWithAccessToken {

    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile : MMECustomProfile,
        MMEStartupDelay: @10,
        MMECustomGeofenceRadius: @1200
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithLogger:logger config:self.preferences];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                       dispatchManager:[[MMEDispatchManager alloc] init]
                                                                logger:logger];

    [self.eventsManager startEventsManagerWithToken:@"fooToken"];
    XCTAssertEqualObjects(self.eventsManager.configuration.accessToken, @"fooToken");
    XCTAssertEqualObjects(self.eventsManager.configuration.legacyUserAgentBase, @"legacy");
    XCTAssertEqualObjects(self.eventsManager.configuration.legacyHostSDKVersion, @"0.0");

}
-(void)testStartWithAccessTokenAgentBaseHostSDKVersion {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile : MMECustomProfile,
        MMEStartupDelay: @10,
        MMECustomGeofenceRadius: @1200
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithLogger:logger config:self.preferences];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                       dispatchManager:[[MMEDispatchManager alloc] init]
                                                                logger:logger];

    [self.eventsManager startEventsManagerWithToken:@"fooToken" userAgentBase:@"bar" hostSDKVersion:@"baz"];
    XCTAssertEqualObjects(self.eventsManager.configuration.accessToken, @"fooToken");
    XCTAssertEqualObjects(self.eventsManager.configuration.legacyUserAgentBase, @"bar");
    XCTAssertEqualObjects(self.eventsManager.configuration.legacyHostSDKVersion, @"baz");
}

-(void)testSkuID {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile : MMECustomProfile,
        MMEStartupDelay: @10,
        MMECustomGeofenceRadius: @1200
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithLogger:logger config:self.preferences];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                       dispatchManager:[[MMEDispatchManager alloc] init]
                                                                logger:logger];

    XCTAssertNil(self.eventsManager.skuId);
    self.eventsManager.skuId = @"Fluffy";
    XCTAssertEqualObjects(self.eventsManager.skuId, @"Fluffy");
}

// TODO: Convert Cedar Tests

/*
describe(@"MMEEventsManager", ^{
    
    __block MMEEventsManager *eventsManager;
    __block MMEDispatchManagerFake *dispatchManager;

    beforeEach(^{
        dispatchManager = [[MMEDispatchManagerFake alloc] init];
        eventsManager = [MMEEventsManager.alloc initShared];

        eventsManager.dispatchManager = dispatchManager;
        eventsManager.locationManager = nice_fake_for(@protocol(MMELocationManager));

        [eventsManager.eventQueue removeAllObjects];

        // set a high MMEEventFlushCount to prevent crossing the threshold in the tests
        [NSUserDefaults.mme_configuration setObject:@1000 forKey:MMEEventFlushCount];
    });
    
    describe(@"- flush", ^{
        
        beforeEach(^{
            id<MMEAPIClient> apiClient = nice_fake_for(@protocol(MMEAPIClient));
            eventsManager.apiClient = apiClient;
        });
        
        context(@"when the events manager is paused", ^{
            beforeEach(^{
                eventsManager.paused = YES;
            });
            
            it(@"does not tell the api client to post events", ^{
                eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
            });
        });
        
        context(@"when the events manager is not paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when no access token has been set", ^{
                beforeEach(^{
                    [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMEAccessToken];
                    [eventsManager flush];
                });
                
                it(@"does NOT tell the api client to post events", ^{
                    eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
                });
            });
            
            context(@"when an access token has been set", ^{
                beforeEach(^{
                    NSUserDefaults.mme_configuration.mme_accessToken = @"access-token";
                });
                
                context(@"when there are no events in the queue", ^{
                    beforeEach(^{
                        eventsManager.eventQueue.count should equal(0);
                        [eventsManager flush];
                    });
                    
                    it(@"does NOT tell the api client to post events", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
                    });
                });
                
                // TODO: move these to an XCTest case
//                context(@"when there are events in the queue", ^{
//                    beforeEach(^{
//                        eventsManager.timerManager = [[MMETimerManager alloc] initWithTimeInterval:1000 target:eventsManager selector:@selector(flush)];
//                        spy_on(eventsManager.timerManager);
//                        [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
//                        [eventsManager flush];
//                    });
//
//                    it(@"tells the api client to post events", ^{
//                        eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:));
//                    });
//
//                    it(@"tells its timer manager to cancel", ^{
//                        eventsManager.timerManager should have_received(@selector(cancel));
//                    });
//
//                    it(@"does nothing if flush is called again", ^{
//                        [(id<CedarDouble>)eventsManager.apiClient reset_sent_messages];
//                        [eventsManager flush];
//                        eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
//                    });
//                });
            });
        });
        
    });
    
    describe(@"- sendTurnstileEvent", ^{
        
        context(@"when next turnstile send date is nil", ^{
            beforeEach(^{
                eventsManager.nextTurnstileSendDate should be_nil;
            });
            
            describe(@"calling the method before setting up required variables", ^{
                beforeEach(^{
                    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
                    spy_on(fakeAPIClient);
                    
                    NSUserDefaults.mme_configuration.mme_accessToken = @"access-token";
                    NSUserDefaults.mme_configuration.mme_legacyUserAgentBase = @"user-agent-base";
                    NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion = @"host-sdk-version";
                    
                    eventsManager.apiClient = fakeAPIClient;
                    });
                
                context(@"when the events manager's api client does not have an access token set", ^{
                    beforeEach(^{
                        [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMEAccessToken];
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's api client does not have a user agent base set", ^{
                    beforeEach(^{
                        [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMELegacyUserAgentBase];
                        [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMELegacyUserAgent];
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's api client does not have a host sdk version set", ^{
                    beforeEach(^{
                        [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMELegacyHostSDKVersion];
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's common even data does not have a vendor id", ^{
                    beforeEach(^{
                        MMEEvent.class stub_method(@selector(vendorId)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's common even data does not have a model", ^{
                    beforeEach(^{
                        MMEEvent.class stub_method(@selector(model)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's common even data does not have a ios version", ^{
                    beforeEach(^{
                        MMEEvent.class stub_method(@selector(osVersion)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
            });
        });
    });
    
    describe(@"- sendTelemetryMetricsEvent", ^{
        context(@"when next telemetryMetrics send date is not nil and event manager is correctly configured", ^{
            beforeEach(^{
                MMEEvent *event = [MMEEvent mapTapEventWithDateString:@"a nice date" attributes:@{@"attribute1": @"a nice attribute"}];
                NSArray *eventQueueFake = [[NSArray alloc] initWithObjects:event, nil];
                eventsManager.eventQueue = [eventQueueFake mutableCopy];
                [eventsManager flush];
                
                MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
                spy_on(fakeAPIClient);
                eventsManager.apiClient = fakeAPIClient;
                
                NSUserDefaults.mme_configuration.mme_accessToken = @"access-token";
                NSUserDefaults.mme_configuration.mme_legacyUserAgentBase = @"user-agent-base";
                NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion = @"host-sdk-version";
                
                spy_on([MMEMetricsManager sharedManager].metrics);
            });
            
            afterEach(^{
                stop_spying_on([MMEMetricsManager sharedManager].metrics);
            });
            
            context(@"when the current time is before the next telemetryMetrics send date", ^{
                beforeEach(^{
                    [MMEMetricsManager sharedManager].metrics stub_method(@selector(recordingStarted)).and_return(NSDate.distantFuture);
                    
                    [eventsManager sendTelemetryMetricsEvent];
                });
                
                it(@"tells its api client to not post events", ^{
                    eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                });
            });
            
            context(@"when the current time is after the next telemetryMetrics send date", ^{
                beforeEach(^{
                    [MMEMetricsManager sharedManager].metrics stub_method(@selector(recordingStarted)).and_return(NSDate.distantPast);
                    [eventsManager sendTelemetryMetricsEvent];
                });
                
                it(@"tells its api client to post events", ^{
                    eventsManager.apiClient should have_received(@selector(postEvent:completionHandler:));
                });
            });
        });
    });
    
    describe(@"- enqueueEventWithName:attributes", ^{
        __block NSString *dateString;
        __block NSDictionary *attributes;
        
        beforeEach(^{
            dateString = @"A nice date";
            NSDateFormatter *dateFormatter = MMEDate.iso8601DateFormatter;
            spy_on(dateFormatter);
            dateFormatter stub_method(@selector(stringFromDate:)).and_return(dateString);
            
            attributes = @{@"attribute1": @"a nice attribute"};
        });
        
        context(@"when the events manager is not paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when a map tap event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapTap attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });

            context(@"when a map drag end event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapDragEnd attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapDragEndEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = [MMEDate dateWithDate:event.date];

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a map download start event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEventTypeOfflineDownloadStart attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapOfflineDownloadStartEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = [MMEDate dateWithDate:event.date];

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a map download end event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEventTypeOfflineDownloadEnd attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapOfflineDownloadEndEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = [MMEDate dateWithDate:event.date];

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a navigation event is pushed", ^{
                __block NSString * navigationEventName = @"navigation.*";
                
                beforeEach(^{
                    [eventsManager enqueueEventWithName:navigationEventName attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent navigationEventWithName:navigationEventName attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a vision event is pushed", ^{
                __block NSString * visionEventName = @"vision.*";
                
                beforeEach(^{
                    [eventsManager enqueueEventWithName:visionEventName attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent visionEventWithName:visionEventName attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a search event is pushed", ^{
                __block NSString * searchEventName = @"search.*";
                
                beforeEach(^{
                    [eventsManager enqueueEventWithName:searchEventName attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent searchEventWithName:searchEventName attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a generic event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:@"generic" attributes:attributes];
                });
                
                it(@"does queue the event", ^{
                    eventsManager.eventQueue.count should equal(1);
                });
            });
        });
    });
    
    describe(@"- enqueueEventWithName:", ^{
        __block NSString *dateString;
        
        beforeEach(^{
            dateString = @"A nice date";
            NSDateFormatter *dateFormatter = MMEDate.iso8601DateFormatter;
            spy_on(dateFormatter);
            dateFormatter stub_method(@selector(stringFromDate:)).and_return(dateString);
        });
        
        context(@"when the events manager is not paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when a map load event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapLoadEventWithDateString:dateString commonEventData:nil];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
        });
        
        context(@"when the events manager is paused", ^{
            beforeEach(^{
                eventsManager.paused = YES;
            });
            
            context(@"when a map load event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                });
                
                it(@"should queue events", ^{
                    eventsManager.eventQueue.count should equal(1);
                });
            });
        });
    });

    describe(@"- pushEvent:", ^{
        beforeEach(^{
            eventsManager.paused = YES;
        });

        context(@"when an error event is pushed", ^{
            NSError* testError = [NSError.alloc initWithDomain:NSCocoaErrorDomain code:999 userInfo:@{
                NSLocalizedDescriptionKey: @"Test Error Description",
                NSLocalizedFailureReasonErrorKey: @"Test Error Failure Reason"
            }];

            it(@"should not queue error events", ^{
                [MMEEventsManager.sharedManager pushEvent:[MMEEvent debugEventWithError:testError]];
                eventsManager.eventQueue.count should equal(0);
            });
        });

        context(@"when an exception event is pushed", ^{
            NSException* testException = [NSException.alloc initWithName:@"TestExceptionName" reason:@"TestExceptionReason" userInfo:nil];

            it(@"should not queue exception events", ^{
                [MMEEventsManager.sharedManager pushEvent:[MMEEvent debugEventWithException:testException]];
                eventsManager.eventQueue.count should equal(0);
            });
        });
    });

    describe(@"MMELocationManagerDelegate", ^{
        
        context(@"-[MMEEventsManager locatizonManager:didVisit:]", ^{
            __block CLVisit *visit;
            
            beforeEach(^{
                eventsManager.delegate = nice_fake_for(@protocol(MMEEventsManagerDelegate));
                eventsManager.paused = NO;
                
                visit = [[CLVisit alloc] init];
                spy_on(visit);
                
                CLLocationCoordinate2D coordinate = {10.0, -10.0};
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
                
                visit stub_method(@selector(coordinate)).and_return(coordinate);
                visit stub_method(@selector(arrivalDate)).and_return(date);
                visit stub_method(@selector(departureDate)).and_return(date);
                visit stub_method(@selector(horizontalAccuracy)).and_return(42.0);
                
                [eventsManager locationManager:eventsManager.locationManager didVisit:visit];
            });
            
            it(@"enqueues the correct event", ^{
                CLLocation *location = [[CLLocation alloc] initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude];
                NSDictionary *attributes = @{
                    MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                    MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                    MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                    MMEEventHorizontalAccuracy: @(visit.horizontalAccuracy),
                    MMEEventKeyArrivalDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.arrivalDate],
                    MMEEventKeyDepartureDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.departureDate]
                };
                MMEEvent *expectedVisitEvent = [MMEEvent visitEventWithAttributes:attributes];
                MMEEvent *enqueueEvent = eventsManager.eventQueue.firstObject;

                expectedVisitEvent.dateStorage = enqueueEvent.dateStorage;

                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                [tempDict addEntriesFromDictionary:enqueueEvent.attributes];
                [tempDict setObject:[MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]] forKey:@"created"];
                enqueueEvent.attributesStorage = tempDict;
                
                enqueueEvent should equal(expectedVisitEvent);
            });
            
            it(@"tells its delegate", ^{
                eventsManager.delegate should have_received(@selector(eventsManager:didVisit:)).with(eventsManager, visit);
            });
        });
    });
});
*/

@end
