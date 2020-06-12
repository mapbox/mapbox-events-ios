#import <XCTest/XCTest.h>
#import "MMEEventsManager.h"
#import "MMEEventsManager_Private.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEUniqueIdentifier.h"
#import "MMEEvent.h"
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
#import "MMEMetricsManagerCallCounter.h"

// MARK: - Private Interfaces of testing
@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) id<MMELocationManaging> locationManager;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, readonly) NSMutableArray<OnURLResponse>* urlResponseListeners;
@property (nonatomic, readonly) NSMutableArray<OnSerializationError>* serializationErrorListeners;

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



@interface MMEAPIClient (Private)
@property (nonatomic, strong) NSMutableArray<OnSerializationError>* onSerializationErrorListeners;
@property (nonatomic, strong) NSMutableArray<OnURLResponse>* onUrlResponseListeners;
@property (nonatomic, strong) NSMutableArray<OnEventQueueUpdate>* onEventQueueUpdateListeners;
@property (nonatomic, strong) NSMutableArray<OnEventCountUpdate>* onEventCountUpdateListeners;
@property (nonatomic, strong) NSMutableArray<OnGenerateTelemetryEvent>* onGenerateTelemetryEventListeners;
@end

@interface MMEEventsManagerTests : XCTestCase <MMEEventsManagerDelegate>
@property (nonatomic, strong) MMEPreferences* preferences;
@property (nonatomic, strong) MMEEventsManager* eventsManager;

// MARK: Delegate Call Counters

@property (nonatomic, strong) NSMutableArray<CLVisit*> *didVisitCalls;
@property (nonatomic, strong) NSMutableArray<MMEEvent*>* didEnqueueEventCalls;
@property (nonatomic, strong) NSMutableArray<NSError*>* didReportErrorCalls;
@property (nonatomic, strong) NSMutableArray<NSArray<CLLocation*>*>* didUpdateLocationCalls;
@property (nonatomic, strong) NSMutableArray<NSArray<MMEEvent *> *>* didSendEventsCalls;


@end

@implementation MMEEventsManagerTests

// MARK: - Lifecycle

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

    self.didVisitCalls = [NSMutableArray array];
    self.didEnqueueEventCalls = [NSMutableArray array];
    self.didReportErrorCalls = [NSMutableArray array];
    self.didUpdateLocationCalls = [NSMutableArray array];
    self.didSendEventsCalls = [NSMutableArray array];

}

- (void)tearDown {

}

// MARK: - MMEEventsManagerDelegate (For Delegate Call Testing)
- (void)eventsManager:(MMEEventsManager *)eventsManager didVisit:(CLVisit *)visit {
    [self.didVisitCalls addObject:visit];
}

- (void)eventsManager:(MMEEventsManager *)eventsManager didEnqueueEvent:(MMEEvent *)enqueued {
    [self.didEnqueueEventCalls addObject:enqueued];
}

- (void)eventsManager:(MMEEventsManager *)eventsManager didEncounterError:(NSError *)error {
    [self.didReportErrorCalls addObject:error];
}

- (void)eventsManager:(MMEEventsManager *)eventsManager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self.didUpdateLocationCalls addObject:locations];
}

- (void)eventsManager:(MMEEventsManager *)eventsManager didSendEvents:(NSArray<MMEEvent *> *)events {
    [self.didSendEventsCalls addObject:events];
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

- (void)testSetupPassiveDataGathering {

    // Expect locationManager to be nil
    XCTAssertNil(self.eventsManager.locationManager);
    
    [self.eventsManager setupPassiveDataCollection];

    // Expect Location Manager To be configured
    XCTAssertNotNil(self.eventsManager.locationManager);
    XCTAssertEqual(self.eventsManager.locationManager.delegate, self.eventsManager);
}

// MARK: - Listeners

- (void)testResponseListener {

    // Register OnResponse Listener
    XCTestExpectation *expectation = [self expectationWithDescription:@"Registered Response listener should receive a callback"];
    __block BOOL hasSeenCallback = false;
    [self.eventsManager registerOnURLResponseListener:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        // Expected at least one callback Error due to invalid access token
        if (!hasSeenCallback) {
            [expectation fulfill];
        }
        hasSeenCallback = YES;
    }];

    XCTAssertEqual(self.eventsManager.urlResponseListeners.count, 1);

    // Start manager
    [self.eventsManager startEventsManagerWithToken:@"coocoo"];

    [self waitForExpectations:@[expectation] timeout:2];
}

- (void)testOnSerializationListener {
    [self.eventsManager registerOnSerializationErrorListener:^(NSError * _Nonnull error) {}];
    XCTAssertEqual(self.eventsManager.serializationErrorListeners.count, 1);
}

// MARK: - Behavior in Various Application States

- (void)testLogLevel {
    self.eventsManager.logLevel = MMELogNone;
    XCTAssertEqual(self.eventsManager.logLevel, MMELogNone);
    self.eventsManager.logLevel = MMELogDebug;
    XCTAssertEqual(self.eventsManager.logLevel, MMELogDebug);
    self.eventsManager.logLevel = MMELogNetwork;
    XCTAssertEqual(self.eventsManager.logLevel, MMELogNetwork);
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

// MARK: - Flush

- (void)testFlushNoAccessToken {

    // Configure Manager with Client
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.accessToken = nil;
    [self.eventsManager.eventQueue addObject:[MMEEvent mapTapEvent]];
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager flush];

    // Expect no api call (Due to missing Access Token)
    XCTAssertEqual(client.performRequestCount, 0);
}

- (void)testFlushEmptyQueue {
    // Configure Manager with Client
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.accessToken = @"abc123";
    [self.eventsManager.eventQueue removeAllObjects];
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager flush];

    // Expect no api call (Due to empty Queue)
    XCTAssertEqual(client.performRequestCount, 0);
}

- (void)testFlush {
    // Configure Manager with Client
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.accessToken = @"abc123";
    [self.eventsManager.eventQueue addObject:[MMEEvent mapTapEvent]];
    self.eventsManager.apiClient = client;
    self.eventsManager.delegate = self;
    self.eventsManager.paused = NO;


    [self.eventsManager flush];

    // Expect Telemetry Metrics Sent


    // Expect Post Events Sent
    XCTAssertEqual(client.performRequestCount, 1);

    // Expect Queuing to be reset
    XCTAssertEqual(self.eventsManager.eventQueue.count, 0);

    // Expect Delegate Messaging
    XCTAssertEqual(self.didSendEventsCalls.count, 1);
}





// MARK: - Event Queue Threadhold Triggers

- (void)testQueueuingPushesToQueueWhilePaused {
    self.eventsManager.paused = true;
    self.eventsManager.delegate = self;

    NSDictionary* attributes = attributes = @{
        @"attribute1": @"a nice attribute"

    };
    NSString *dateString = @"A nice date";
    MMEEvent *event = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];

    [self.eventsManager enqueueEvent:event];

    // Verify Event was queued
    XCTAssertEqual(self.eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects(self.eventsManager.eventQueue.firstObject, event);

    // Verify Delegate was notified of queuing
    XCTAssertEqualObjects(self.didEnqueueEventCalls.firstObject, event);
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

- (void)testSendTurnstileCompletionSuccess {

    self.eventsManager.nextTurnstileSendDate = nil;
    [self.eventsManager sendTurnstileEventCompletionHandler:nil];

    // Expect Next Turnstile to not be updated
    XCTAssertEqualObjects(self.eventsManager.nextTurnstileSendDate, [NSDate.date mme_startOfTomorrow]);
}

- (void)testSendTurnstileCompletionFailure {
    self.eventsManager.nextTurnstileSendDate = nil;
    NSError *error = [NSError errorWithDomain:@"domain" code:100 userInfo:@{}];
    [self.eventsManager sendTurnstileEventCompletionHandler:error];

    // Expect Next Turnstile to not be updated
    XCTAssertNil(self.eventsManager.nextTurnstileSendDate);
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
    self.eventsManager.delegate = self;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:0.001 longitude:0.001];
    NSArray *locations = @[location, location2];

    [self.eventsManager locationManager:self.eventsManager.locationManager didUpdateLocations:locations];
    XCTAssertEqual(self.eventsManager.eventQueue.count, 2);
    XCTAssertEqual(self.didUpdateLocationCalls.count, 1);

    // Expect Delegate to be notified
    XCTAssertEqual(self.didUpdateLocationCalls.firstObject, locations);


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
    self.eventsManager.delegate = self;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:0.001 longitude:0.001];
    NSArray *locations = @[location, location2];

    [self.eventsManager locationManager:self.eventsManager.locationManager didUpdateLocations:locations];
    XCTAssertEqual(self.eventsManager.eventQueue.count, 2);

    // Expect Delegate to be notified
    XCTAssertEqual(self.didUpdateLocationCalls.firstObject, locations);
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
    self.preferences.eventFlushCount = 5;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Clear Access Token
    self.preferences.accessToken = nil;

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager sendTurnstileEvent];

    // A turnstile init error results in the queing of an error event
    XCTAssertEqual(self.eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects(self.eventsManager.eventQueue.firstObject.name, @"mobile.crash");
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

-(void)testNoUserAgentBaseDoesNotPost {
    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 5;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Clear Access Token
    self.preferences.legacyUserAgentBase = nil;

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager sendTurnstileEvent];

    // Given Turnstile Event generated an error, an error event should be queued for sending
    XCTAssertEqual(self.eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects(self.eventsManager.eventQueue.firstObject.name, @"mobile.crash");
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

-(void)testNoHostSDKVersionBaseDoesNotPost {
    // Configure Client with
    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: self.preferences];
    self.preferences.eventFlushCount = 5;

    [self.eventsManager startEventsManagerWithToken:@"access-token"];

    // Clear Access Token
    self.preferences.legacyHostSDKVersion = nil;

    // Set Client after starting to replace client which is created on start
    self.eventsManager.apiClient = client;
    self.eventsManager.paused = NO;

    [self.eventsManager sendTurnstileEvent];

    // Given Turnstile Event generated an error, an error event should be queued for sending
    XCTAssertEqual(self.eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects(self.eventsManager.eventQueue.firstObject.name, @"mobile.crash");
    XCTAssertEqual(client.postEventsCount, 0);
    XCTAssertEqual(client.performRequestCount, 0);
}

- (void)testPostEventsCompletionSuccess {
    MMEEvent *event = [MMEEvent eventWithName:@"Foo" attributes:@{}];

    // Values Set during request
    self.eventsManager.backgroundTaskIdentifier = 15;
    [self.eventsManager postEventsCompletionHandler:@[event] error:nil];

    // Expect background identifier to be reset
    XCTAssertEqual(self.eventsManager.backgroundTaskIdentifier, UIBackgroundTaskInvalid);
}

- (void)testPostEventsCompletionError {
    MMEEvent *event = [MMEEvent eventWithName:@"Foo" attributes:@{}];
    NSError *error = [NSError errorWithDomain:@"domain" code:100 userInfo:@{}];

    // Values Set during request
    self.eventsManager.backgroundTaskIdentifier = 15;
    [self.eventsManager postEventsCompletionHandler:@[event] error:error];

    // Expedt background identifier to be reset
    XCTAssertEqual(self.eventsManager.backgroundTaskIdentifier, UIBackgroundTaskInvalid);
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
    self.eventsManager.delegate = self;

    // Call Delegate Method
    [self.eventsManager locationManager:self.eventsManager.locationManager didVisit:visit];

    // Verify the Event was constructed as expected AND has been enqueued
    XCTAssertNotNil(self.eventsManager.eventQueue.firstObject);
    XCTAssertEqualObjects((MMEEvent*)self.eventsManager.eventQueue.firstObject.attributes[MMEEventKeyEvent], MMEEventTypeVisit);

    // Verify Events Manager notified delegate of the visit
    XCTAssertEqual(self.didVisitCalls.count, 1);
    XCTAssertEqualObjects(self.didVisitCalls.firstObject, visit);
}
#endif



-(void)testRegisterOnResponseBlock {
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] initWithDefaults];
    __block BOOL hasSeenCallback = false;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect Response Closure to be called on netowork call"];

    [eventsManager registerOnURLResponseListener:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!hasSeenCallback) {
            hasSeenCallback = true;
            [expectation fulfill];
        }
    }];

    [eventsManager startEventsManagerWithToken:@"token"];

    [self waitForExpectations:@[expectation] timeout:2];
}

-(void)testClientListenerConfiguration {

    // Configure with lengthy startup delay to run tests without passive data collection adding extra events
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEStartupDelay: @200,
    }];
    MMEPreferences *preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManagerCallCounter* metricsManager = [[MMEMetricsManagerCallCounter alloc] initWithConfig:preferences
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:self.preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                                logger:logger];

    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: preferences];
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] initWithDefaults];

    // Configure directly with client allowing for verification this method is doing it's job
    // without the additional side effect of starting.
    [eventsManager configureClientListeners:client];

    // Ensure All Client LIsteners have been registered
    XCTAssertEqual(client.registerOnSerializationErrorListenerCount, 1);
    XCTAssertEqual(client.registerOnURLResponseCount, 1);
    XCTAssertEqual(client.registerOnEventQueueUpdateCount, 1);
    XCTAssertEqual(client.registerOnEventCountUpdateCount, 1);
    XCTAssertEqual(client.registerOnGenerateTelemetryEventCount, 1);
}

-(void)testOnSerializationErrorHandling {

    // Configure with lengthy startup delay to run tests without passive data collection adding extra events
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEStartupDelay: @200,
    }];
    MMEPreferences *preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                               dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManagerCallCounter* metricsManager = [[MMEMetricsManagerCallCounter alloc] initWithConfig:preferences
                                                                                  pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: preferences];
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] initWithPreferences:preferences
                                                                   uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:preferences.identifierRotationInterval]
                                                                        application:[[MMEUIApplicationWrapperFake alloc] init]
                                                                     metricsManager:metricsManager
                                                                             logger:logger];

    // Configure directly with client allowing for verification this method is doing it's job
    // without the additional side effect of starting.
    [eventsManager configureClientListeners:client];
    
    // Verify Registered Behaviors perform as expected
    for (OnSerializationError listener in client.onSerializationErrorListeners) {
        NSError *error = [NSError errorWithDomain:@"MMEEventsManagerTestsDomain" code:1 userInfo:nil];
        listener(error);
    }

    // Expect single error to have been queued
    XCTAssertEqual(eventsManager.eventQueue.count, 1);
    XCTAssertEqualObjects([eventsManager.eventQueue.lastObject name], @"mobile.crash");
}

-(void)testResponseListenerHandling {
    // Configure with lengthy startup delay to run tests without passive data collection adding extra events
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEStartupDelay: @200,
    }];
    MMEPreferences *preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                               dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManagerCallCounter* metricsManager = [[MMEMetricsManagerCallCounter alloc] initWithConfig:preferences
                                                                                  pendingMetricsFileURL:[NSURL testPendingEventsFile]];


    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: preferences];
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] initWithPreferences:preferences
                                                                   uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:preferences.identifierRotationInterval]
                                                                        application:[[MMEUIApplicationWrapperFake alloc] init]
                                                                     metricsManager:metricsManager
                                                                             logger:logger];

    // Configure directly with client allowing for verification this method is doing it's job
    // without the additional side effect of starting.
    [eventsManager configureClientListeners:client];

    // Mock Data to be used
    NSURL *url = [NSURL URLWithString:@"https://mapbox.com"];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPBody = data;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:nil headerFields:@{}];

    for (OnURLResponse listener in client.onUrlResponseListeners) {
        listener(data, request, response, nil);
    }

    // Expect the tracking of Received bytes to have been forwarded to metricsManager
    XCTAssertEqual(metricsManager.updateSentBytesCallCount, 1);
    XCTAssertEqual(metricsManager.updateReceivedBytesCallCount, 1);
    XCTAssertEqual(metricsManager.metrics.totalBytesSent, 2);
    XCTAssertEqual(metricsManager.metrics.totalBytesReceived, 2);
}

-(void)testOnUpdateEventQueueHandling {
    // Configure with lengthy startup delay to run tests without passive data collection adding extra events
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEStartupDelay: @200,
    }];
    MMEPreferences *preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                               dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManagerCallCounter* metricsManager = [[MMEMetricsManagerCallCounter alloc] initWithConfig:preferences
                                                                                  pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: preferences];
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                                   uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:preferences.identifierRotationInterval]
                                                                        application:[[MMEUIApplicationWrapperFake alloc] init]
                                                                     metricsManager:metricsManager
                                                                             logger:logger];

    // Configure directly with client allowing for verification this method is doing it's job
    // without the additional side effect of starting.
    [eventsManager configureClientListeners:client];

    for (OnEventQueueUpdate listener in client.onEventQueueUpdateListeners) {
        MMEEvent *event = [MMEEvent eventWithName:@"Foo" attributes:@{}];
        listener(@[event]);
    }

    // Expect a single call to update Metrics Manager
    XCTAssertEqual(metricsManager.updateFromEventQueueCallCount, 1);
}

-(void)testOnEventCountUpdateHandling {
    // Configure with lengthy startup delay to run tests without passive data collection adding extra events
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEStartupDelay: @200,
    }];
    MMEPreferences *preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                               dataStore:NSUserDefaults.mme_configuration];


    MMELogger* logger = [[MMELogger alloc] init];
    MMEMetricsManagerCallCounter* metricsManager = [[MMEMetricsManagerCallCounter alloc] initWithConfig:preferences
                                                                                  pendingMetricsFileURL:[NSURL testPendingEventsFile]];

    MMEAPIClientCallCounter* client = [[MMEAPIClientCallCounter alloc] initWithConfig: preferences];
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] initWithPreferences:self.preferences
                                                                   uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:preferences.identifierRotationInterval]
                                                                        application:[[MMEUIApplicationWrapperFake alloc] init]
                                                                     metricsManager:metricsManager
                                                                             logger:logger];

    // Configure directly with client allowing for verification this method is doing it's job
    // without the additional side effect of starting.
    [eventsManager configureClientListeners:client];

    for (OnEventCountUpdate listener in client.onEventCountUpdateListeners) {
        listener(1, nil, nil);
    }
    // Expect Update from EventCount
    XCTAssertEqual(metricsManager.updateFromEventCountCallCount, 1);
}

- (void)testReportError {
    self.eventsManager.delegate = self;

    NSError *error = [NSError errorWithDomain:@"domain" code:100 userInfo:@{}];
    [self.eventsManager reportError:error];

    XCTAssertEqual(self.didReportErrorCalls.count, 1);
    XCTAssertEqualObjects(self.didReportErrorCalls.firstObject, error);
}

// MARK: - Deprecated Create & Push

- (void)testCreateAndPush {

    // Pause Manager and queue up events
    self.eventsManager.paused = YES;

    // Map Events (Expect Events to be created and queued)
    [self.eventsManager createAndPushEventBasedOnName:@"map.load" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], MMEEventTypeMapLoad);
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    [self.eventsManager createAndPushEventBasedOnName:@"map.click" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], MMEEventTypeMapTap);
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    [self.eventsManager createAndPushEventBasedOnName:@"map.dragend" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], MMEEventTypeMapDragEnd);
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    [self.eventsManager createAndPushEventBasedOnName:@"map.offlineDownload.start" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], MMEventTypeOfflineDownloadStart);
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    [self.eventsManager createAndPushEventBasedOnName:@"map.offlineDownload.end" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], MMEventTypeOfflineDownloadEnd);
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    // Navigation Events (Expect events to be created and queue)
    [self.eventsManager createAndPushEventBasedOnName:@"navigation.depart" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], MMEEventTypeNavigationDepart);
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    // Vision Events
    [self.eventsManager createAndPushEventBasedOnName:@"vision.viewed" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], @"vision.viewed");
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    // Search Events
    [self.eventsManager createAndPushEventBasedOnName:@"search.searched" attributes:@{}];
    XCTAssertEqualObjects(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyEvent], @"search.searched");
    XCTAssertNotNil(self.eventsManager.eventQueue.lastObject.attributes[MMEEventKeyCreated]);

    // Unsupported Event, expect to queue up as generic event
    [self.eventsManager createAndPushEventBasedOnName:@"millions.of.peaches" attributes:@{
        @"peaches": @"for me"
    }];
    NSDictionary *attributes = [self.eventsManager.eventQueue.lastObject attributes];
    XCTAssertEqualObjects(attributes[MMEEventKeyEvent], @"millions.of.peaches");
    XCTAssertNotNil(attributes[MMEEventKeyCreated]);

}

@end
