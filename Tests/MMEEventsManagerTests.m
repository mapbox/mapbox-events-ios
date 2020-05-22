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
#import "MMEEventsManager_Private.h"
#import "MMEBundleInfoFake.h"
#import "NSURL+Files.h"
#import "MMEMockEventConfig.h"
#import "MMEAPIClientFake.h"
#import "MMEAPIClientCallCounter.h"
#import "MockVisit.h"
#import "CLLocation+Mocks.h"

// MARK: - Private Interfaces of testing
@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

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

    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithConfig:self.preferences
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]];


    self.preferences.accessToken = @"access-token";
    self.preferences.isCollectionEnabled = YES;

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                            application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                                logger:logger];

}

- (void)tearDown {

}

// MARK: - Starting Events Manager should not initialize a new object


- (void)testEventsManagerReinitialized {
    MMEEventsManager *capturedEventsManager = self.eventsManager;
    [self.eventsManager startEventsManagerWithToken:@"access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"sdk-version"];

    XCTAssert([self.eventsManager isEqual:capturedEventsManager]);
}

- (void)testEventsManagerReinitializedLegacy {
    MMEEventsManager *capturedEventsManager = self.eventsManager;
    [self.eventsManager initializeWithAccessToken:@"access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"sdk-version"];

    XCTAssert([self.eventsManager isEqual:capturedEventsManager]);
}

// MARK: - Listeners

- (void)testResponseListener {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Registered Response listener should receive a callback"];
    __block BOOL hasSeenCallback = false;
    [self.eventsManager registerOnURLResponseListener:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        // Expected at least one callback Error due to invalid access token
        if (!hasSeenCallback) {
            [expectation fulfill];
        }
        hasSeenCallback = YES;
    }];

    [self.eventsManager startEventsManagerWithToken:@"coocoo"];

    [self waitForExpectations:@[expectation] timeout:2];
}

// MARK: - Behavior in Various Application States

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

// MARK: - Event Queue Threadhold Triggers

- (void)testQueueuingPushesToQueueWhilePaused {
    self.eventsManager.paused = true;

    NSDictionary* attributes = attributes = @{
        @"attribute1": @"a nice attribute"

    };
    NSString *dateString = @"A nice date";
    MMEEvent *event = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    [self.eventsManager enqueueEvent:event];

    XCTAssertEqual(self.eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects(self.eventsManager.eventQueue.firstObject, event);
}

- (void)testQueueuingPushesToQueueWhileActive {
    self.eventsManager.paused = false;

    NSDictionary* attributes = attributes = @{
        @"attribute1": @"a nice attribute"

    };
    NSString *dateString = @"A nice date";
    MMEEvent *event = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];

    [self.eventsManager enqueueEvent:event];

    XCTAssertEqual(self.eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects(self.eventsManager.eventQueue.firstObject, event);
}

- (void)testEventQueuedAndFlushed {
    self.eventsManager.paused = NO;
    [self.eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
    XCTAssert(self.eventsManager.eventQueue.count > 0);

    [self.eventsManager pauseOrResumeMetricsCollectionIfRequired];
    XCTAssert(self.eventsManager.eventQueue.count == 0);
    XCTAssert(self.eventsManager.paused = YES);
}

- (void)testEventCountThresholdReached {
    self.eventsManager.paused = NO;

    [self.preferences setEventFlushCount:2];

    MMEEvent *event = [MMEEvent locationEventWithID:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                           location:CLLocation.mapboxOffice];
                            
    [self.eventsManager pushEvent:event];
    XCTAssert(self.eventsManager.eventQueue.count > 0);

    [self.eventsManager pushEvent:event];
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
}

- (void)testTimerReachedWithEventQueued {
    self.eventsManager.paused = NO;

    MMEEvent *event = [MMEEvent locationEventWithID:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                           location:CLLocation.mapboxOffice];
    [self.eventsManager pushEvent:event];
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

    MMEEvent *event = [MMEEvent locationEventWithID:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                           location:CLLocation.mapboxOffice];

    
    [self.eventsManager pushEvent:event];
    XCTAssert(self.eventsManager.eventQueue.count > 0);
    
    self.eventsManager.paused = NO;
    
    self.preferences.isCollectionEnabled = NO;

    [self.eventsManager processAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways andApplicationState:UIApplicationStateActive];
    XCTAssertTrue(self.eventsManager.paused);
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
}

- (void)testPauseOrResumeFlushInBackground {
    self.eventsManager.paused = NO;
    
    MMEEvent *event = [MMEEvent locationEventWithID:self.eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                           location:CLLocation.mapboxOffice];

    [self.eventsManager pushEvent:event];
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
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithConfig:self.preferences
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
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
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithConfig:self.preferences
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
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
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithConfig:self.preferences
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                                logger:logger];

    XCTAssertNil(self.eventsManager.skuId);
    self.eventsManager.skuId = @"Fluffy";
    XCTAssertEqualObjects(self.eventsManager.skuId, @"Fluffy");
}

// MARK: - Pausing

-(void)testPauseEnsuresEventsAreNotSent {

    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 1;
    self.eventsManager.paused = true;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];
    self.eventsManager.apiClient = client;

    // Enqueue more events than the flush count
    NSArray<MMEEvent*>* events = @[
        [MMEEvent locationEventWithID:@"instance-id-1" location:CLLocation.mapboxOffice],
        [MMEEvent locationEventWithID:@"instance-id-2" location:CLLocation.mapboxOffice],
        [MMEEvent locationEventWithID:@"instance-id-3" location:CLLocation.mapboxOffice]
    ];

    for (MMEEvent* event in events) {
        [self.eventsManager enqueueEvent:event];
    }

    // Verify we aren't sending events while EventsManager is paushed
    XCTAssertEqual(self.eventsManager.eventQueue.count, events.count);
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

-(void)testUnpauseWaitsUntilFlushCountToSend {

    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 4;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    // Enqueue more events than the flush count
    NSArray<MMEEvent*>* events = @[
        [MMEEvent locationEventWithID:@"instance-id-1" location:CLLocation.mapboxOffice],
        [MMEEvent locationEventWithID:@"instance-id-2" location:CLLocation.mapboxOffice],
        [MMEEvent locationEventWithID:@"instance-id-3" location:CLLocation.mapboxOffice]
    ];

    for (MMEEvent* event in events) {
        [self.eventsManager enqueueEvent:event];
    }

    // Verify we aren't sending events while EventsManager is paushed
    XCTAssertEqual(self.eventsManager.eventQueue.count, events.count);
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);

    MMEEvent* eventFour = [MMEEvent locationEventWithID:@"instance-id-4" location:CLLocation.mapboxOffice];
    [self.eventsManager enqueueEvent:eventFour];

    // Verify Client has received instruction to send events
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
    XCTAssertEqual(client.postEventsCount, 1);
    XCTAssertEqual(client.performRequestCount, 1);
}

// MARK: - Turnstile (Minimum Requirements for sending)

-(void)testNoAccessTokenDoesNotPost {
    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 1;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Clear Access Token
    self.preferences.accessToken = nil;

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager sendTurnstileEvent];

    // Turnstile events are directly posted, not queued, so there should be nothing queued
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

-(void)testNoUserAgentBaseDoesNotPost {
    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 1;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Clear Access Token
    self.preferences.legacyUserAgentBase = nil;

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager sendTurnstileEvent];

    // Turnstile events are directly posted, not queued, so there should be nothing queued
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

-(void)testNoHostSDKVersionBaseDoesNotPost {
    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 1;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Clear Access Token
    self.preferences.legacyHostSDKVersion = nil;

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager sendTurnstileEvent];

    // Turnstile events are directly posted, not queued, so there should be nothing queued
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

// MARK: - Location Manager Interface

#if TARGET_OS_IOS

// TODO: Perhaps the majority of tests related to event structure could move to events tests?
-(void)testLocationManagerDidVisit {

    CLLocationCoordinate2D coordinate = {10.0, -10.0};
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    CLLocation* location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:13
                                               horizontalAccuracy:7
                                                 verticalAccuracy:7
                                                        timestamp:date];

    MockVisit* visit = [[MockVisit alloc] initWithArrivalDate:date
                                                departureDate:date
                                                   coordinate:location.coordinate
                                           horizontalAccuracy:location.horizontalAccuracy];


    self.eventsManager.paused = YES;

    // Call Delegate Method
    [self.eventsManager locationManager:self.eventsManager.locationManager didVisit:visit];

    // Verify the Event was constructed as expected AND has been enqueued
    XCTAssertNotNil(self.eventsManager.eventQueue.firstObject);
    XCTAssertEqualObjects((MMEEvent*)self.eventsManager.eventQueue.firstObject.attributes[MMEEventKeyEvent], MMEEventTypeVisit);
}
#endif

@end
