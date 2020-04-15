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

- (void)testPauseOrResumeMetricsCollectionIfRequiredPausedToResumed {
    MMELocationManagerFake *locationManager = [[MMELocationManagerFake alloc] init];
    [MMEEventsManager sharedManager].locationManager = locationManager;
    
    // When metrics are enabled
    [MMEEventsManager sharedManager].metricsEnabledInSimulator = YES;
    
    // When metrics are paused and pause or resume is called
    [MMEEventsManager sharedManager].commonEventData = nil;
    [MMEEventsManager sharedManager].paused = YES;
    [[MMEEventsManager sharedManager] pauseOrResumeMetricsCollectionIfRequired];
    
    // Metrics are resumed
    XCTAssertFalse([MMEEventsManager sharedManager].paused);
    XCTAssertNotNil([MMEEventsManager sharedManager].commonEventData);
    XCTAssertTrue([locationManager received:@selector(startUpdatingLocation)]);
    
    // When metrics are **not** enabled
    [locationManager resetReceivedSelectors];
    [MMEEventsManager sharedManager].metricsEnabledInSimulator = NO;
    
    // When metrics are paused and pause or resume is called
    [MMEEventsManager sharedManager].commonEventData = nil;
    [MMEEventsManager sharedManager].paused = YES;
    [[MMEEventsManager sharedManager] pauseOrResumeMetricsCollectionIfRequired];
    
    // Metrics are **not** resumed
    XCTAssertTrue([MMEEventsManager sharedManager].paused);
    XCTAssertNil([MMEEventsManager sharedManager].commonEventData);
    XCTAssertFalse([locationManager received:@selector(startUpdatingLocation)]);
}

- (void)testPauseOrResumeMetricsCollectionIfRequiredResumedToPaused {
    MMELocationManagerFake *locationManager = [[MMELocationManagerFake alloc] init];
    [MMEEventsManager sharedManager].locationManager = locationManager;
    
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.accessToken = accessToken;
    apiClient.userAgentBase = userAgentBase;
    [MMEEventsManager sharedManager].apiClient = apiClient;
    
    // When metrics are **not** enabled
    [MMEEventsManager sharedManager].metricsEnabledInSimulator = NO;
    
    // When metrics are resumed and pause or resume is called
    [MMEEventsManager sharedManager].paused = NO;
    [[MMEEventsManager sharedManager] pauseOrResumeMetricsCollectionIfRequired];
    
    // Metrics are paused
    XCTAssertTrue([MMEEventsManager sharedManager].paused);
    
    // Metrics are flushed
    XCTAssertTrue([apiClient received:@selector(postEvents:completionHandler:)]);
    XCTAssertNil([MMEEventsManager sharedManager].commonEventData);
    XCTAssertTrue([locationManager received:@selector(stopUpdatingLocation)]);
    
    // When metrics are **not** enabled
    [locationManager resetReceivedSelectors];
    [MMEEventsManager sharedManager].metricsEnabledInSimulator = YES;
    
    // When metrics are resumed and pause or resume is called
    [MMEEventsManager sharedManager].paused = NO;
    [[MMEEventsManager sharedManager] pauseOrResumeMetricsCollectionIfRequired];
    
    // Metrics are **not** paused
    XCTAssertFalse([MMEEventsManager sharedManager].paused);
}

- (void)testAsADelegateForLocationManagerDidUpdateLocations {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    NSString *hostSDKVersion = @"host-sdk-1";
    
    [[MMEEventsManager sharedManager] initializeWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.accessToken, accessToken);
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.userAgentBase, userAgentBase);
    
    [MMEEventsManager sharedManager].metricsEnabledInSimulator = YES;
    [[MMEEventsManager sharedManager] resumeMetricsCollection];
    
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.accessToken = accessToken;
    apiClient.userAgentBase = userAgentBase;
    [MMEEventsManager sharedManager].apiClient = apiClient;
    
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = 1;
    [MMEEventsManager sharedManager].configuration = configuration;
    
    MMECommonEventData *dataStub = [[MMECommonEventData alloc] init];
    dataStub.iOSVersion = @"iOS-version";
    [MMEEventsManager sharedManager].commonEventData = dataStub;
    
    MMENSDateWrapperFake *dateWrapper = [[MMENSDateWrapperFake alloc] init];
    dateWrapper.testDate = [NSDate dateWithTimeIntervalSince1970:2000];
    [MMEEventsManager sharedManager].dateWrapper = dateWrapper;
    
    CLLocation *location = [self location];
    [[MMEEventsManager sharedManager] locationManager:nil didUpdateLocations:@[location]];
    
    MMEMutableMapboxEventAttributes *attributes = [NSMutableDictionary dictionary];
    attributes[MMEEventKeyEvent] = MMEEventTypeLocation;
    attributes[MMEEventKeySource] = MMEEventSource;
    attributes[MMEEventKeySessionId] = [[MMEUniqueIdentifierFake alloc] init].rollingInstanceIdentifer;
    attributes[MMEEventKeyOperatingSystem] = dataStub.iOSVersion;
    attributes[MMEEventKeyApplicationState] = [dataStub applicationState];
    attributes[MMEEventKeyCreated] =  [dateWrapper formattedDateStringForDate:[location timestamp]];
    attributes[MMEEventKeyLatitude] = @([location mme_latitudeRoundedWithPrecision:7]);
    attributes[MMEEventKeyLongitude] = @([location mme_longitudeRoundedWithPrecision:7]);
    attributes[MMEEventKeyAltitude] = @([location mme_roundedAltitude]);
    attributes[MMEEventHorizontalAccuracy] = @(location.horizontalAccuracy);
    
    XCTAssertTrue([apiClient received:@selector(postEvents:completionHandler:)]);
    
    NSArray *arguments = [apiClient.argumentsBySelector[[NSValue valueWithPointer:@selector(postEvents:completionHandler:)]] firstObject];
    XCTAssertTrue(arguments.count == 1);
    MMEEvent *event = arguments.firstObject;
    XCTAssertEqualObjects(event.attributes, attributes);
}

- (void)testAsADelegateForLocationManagerAfterTimeThreshold {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    NSString *hostSDKVersion = @"host-sdk-1";
    
    [[MMEEventsManager sharedManager] initializeWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.accessToken, accessToken);
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.userAgentBase, userAgentBase);
    
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.accessToken = accessToken;
    apiClient.userAgentBase = userAgentBase;
    [MMEEventsManager sharedManager].apiClient = apiClient;
    
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = 100;
    configuration.eventFlushSecondsThreshold = 1;
    [MMEEventsManager sharedManager].configuration = configuration;
    
    MMETimerManagerFake *timerManager = [[MMETimerManagerFake alloc] init];
    timerManager.target = [MMEEventsManager sharedManager];
    timerManager.selector = @selector(flush);
    [MMEEventsManager sharedManager].timerManager = timerManager;
    
    MMECommonEventData *dataStub = [[MMECommonEventData alloc] init];
    dataStub.iOSVersion = @"iOS-version";
    [MMEEventsManager sharedManager].commonEventData = dataStub;
    [MMEEventsManager sharedManager].paused = NO;
    
    CLLocation *location = [self location];
    [[MMEEventsManager sharedManager] locationManager:nil didUpdateLocations:@[location]];
    
    [timerManager triggerTimer];
    
    XCTAssertTrue([apiClient received:@selector(postEvents:completionHandler:)]);
}

- (void)testAsADelegateForLocationManagerBeforeEventFlushThreshold {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    NSString *hostSDKVersion = @"host-sdk-1";
    
    [[MMEEventsManager sharedManager] initializeWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.accessToken, accessToken);
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.userAgentBase, userAgentBase);
    
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.accessToken = accessToken;
    apiClient.userAgentBase = userAgentBase;
    [MMEEventsManager sharedManager].apiClient = apiClient;
    
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = 2;
    [MMEEventsManager sharedManager].configuration = configuration;
    
    MMECommonEventData *dataStub = [[MMECommonEventData alloc] init];
    dataStub.iOSVersion = @"iOS-version";
    [MMEEventsManager sharedManager].commonEventData = dataStub;
    
    [[MMEEventsManager sharedManager] locationManager:nil didUpdateLocations:@[[self location]]];
    
    XCTAssertFalse([apiClient received:@selector(postEvents:completionHandler:)]);
}

- (void)testFlushWithNoEvents {
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.accessToken = @"access-token";
    apiClient.userAgentBase = @"user-agent";
    [MMEEventsManager sharedManager].apiClient = apiClient;
    [[MMEEventsManager sharedManager] flush];
    XCTAssertFalse([apiClient received:@selector(postEvents:completionHandler:)]);
}

- (void)testSendTurnstileEventWithSuccess {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    NSString *hostSDKVersion = @"host-sdk-1";
    MMEEventsManager *manager = [MMEEventsManager sharedManager];
    [manager initializeWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    MMENSDateWrapperFake *dateWrapperFake = [[MMENSDateWrapperFake alloc] init];
    dateWrapperFake.testDate = [NSDate dateWithTimeIntervalSince1970:1000];
    manager.dateWrapper = dateWrapperFake;
    
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.userAgentBase = @"user-agent-base";
    apiClient.accessToken = @"access-token";
    apiClient.hostSDKVersion = @"42";
    manager.apiClient = apiClient;
    
    manager.metricsEnabledInSimulator = YES;
    
    XCTAssertNil(manager.nextTurnstileSendDate);
    XCTAssertNotNil(manager.commonEventData.vendorId);
    
    [manager sendTurnstileEvent];
    XCTAssertTrue([apiClient received:@selector(postEvent:completionHandler:)]);
    
    NSValue *lookup = [NSValue valueWithPointer:@selector(postEvent:completionHandler:)];
    NSArray *args = apiClient.argumentsBySelector[lookup];
    MMEEvent *event = args.firstObject;
    XCTAssertTrue(event.name == MMEEventTypeAppUserTurnstile);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyCreated], @"1970-01-01T00:16:40.000+0000");
    XCTAssertEqualObjects(event.attributes[MMEEventKeyEnabledTelemetry], @(1));
    XCTAssertEqualObjects(event.attributes[MMEEventKeyEvent], MMEEventTypeAppUserTurnstile);
    XCTAssertNotNil(event.attributes[MMEEventKeyVendorID]);
    XCTAssertNotNil(event.attributes[MMEEventKeyOperatingSystem]);
    XCTAssertNotNil(event.attributes[MMEEventKeyEnabledTelemetry]);
    XCTAssertNotNil(event.attributes[MMEEventKeyDevice]);
    XCTAssertEqualObjects(event.attributes[MMEEventSDKIdentifier], apiClient.userAgentBase);
    XCTAssertEqualObjects(event.attributes[MMEEventSDKVersion], apiClient.hostSDKVersion);
    
    [apiClient completePostingEventsWithError:nil];
    XCTAssertNotNil(manager.nextTurnstileSendDate);
    
    // Any subsequent calls to send more turnstile events are no-ops
    [apiClient resetReceivedSelectors];
    [manager sendTurnstileEvent];
    XCTAssertFalse([apiClient received:@selector(postEvent:completionHandler:)]);
}

- (void)testEnqueueMapLoadEvent {
    MMEEventsManager *eventsManager = [MMEEventsManager sharedManager];
    MMENSDateWrapperFake *dateWrapperFake = [[MMENSDateWrapperFake alloc] init];
    dateWrapperFake.testDate = [NSDate dateWithTimeIntervalSince1970:2000];
    eventsManager.dateWrapper = dateWrapperFake;
    eventsManager.metricsEnabledInSimulator = YES;
    [eventsManager resumeMetricsCollection];
    
    MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
    commonEventData.iOSVersion = @"iOS-version";
    commonEventData.vendorId = @"vendor-id";
    commonEventData.model = @"model";
    commonEventData.scale = 42;
    eventsManager.commonEventData = commonEventData;
    
    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
    MMEEvent *event = eventsManager.eventQueue.firstObject;
    
    XCTAssertEqualObjects(event.name, MMEEventTypeMapLoad);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyEvent], MMEEventTypeMapLoad);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyCreated], @"1970-01-01T00:33:20.000+0000");
    XCTAssertEqualObjects(event.attributes[MMEEventKeyVendorID], commonEventData.vendorId);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyModel], commonEventData.model);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyOperatingSystem], commonEventData.iOSVersion);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyResolution], @(commonEventData.scale));
    XCTAssertTrue([event.attributes.allKeys containsObject:MMEEventKeyAccessibilityFontScale]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyResolution], @(commonEventData.scale));
    XCTAssertNotNil(event.attributes[MMEEventKeyOrientation]);
    XCTAssertTrue([event.attributes.allKeys containsObject:MMEEventKeyWifi]);
    
    // When the events manager is paused
    
    [eventsManager pauseMetricsCollection];
    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
    XCTAssertTrue(eventsManager.eventQueue.count == 0);
}

- (void)testEnqueueMapTapEvent {
    MMEEventsManager *eventsManager = [MMEEventsManager sharedManager];
    MMENSDateWrapperFake *dateWrapperFake = [[MMENSDateWrapperFake alloc] init];
    dateWrapperFake.testDate = [NSDate dateWithTimeIntervalSince1970:3000];
    eventsManager.dateWrapper = dateWrapperFake;
    eventsManager.metricsEnabledInSimulator = YES;
    [eventsManager resumeMetricsCollection];
    
    NSDictionary *eventAttributes = @{MMEEventKeyLatitude: @(10),
                                      MMEEventKeyLongitude: @(-10),
                                      MMEEventKeyZoomLevel: @(42),
                                      MMEEventKeyGestureID: MMEEventGestureSingleTap};
    [eventsManager enqueueEventWithName:MMEEventTypeMapTap attributes:eventAttributes];
    
    MMEEvent *event = eventsManager.eventQueue.firstObject;
    XCTAssertEqualObjects(event.name, MMEEventTypeMapTap);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyEvent], MMEEventTypeMapTap);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyCreated], @"1970-01-01T00:50:00.000+0000");
    XCTAssertNotNil(event.attributes[MMEEventKeyOrientation]);
    XCTAssertTrue([event.attributes.allKeys containsObject:MMEEventKeyWifi]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyLatitude], eventAttributes[MMEEventKeyLatitude]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyLongitude], eventAttributes[MMEEventKeyLongitude]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyZoomLevel], eventAttributes[MMEEventKeyZoomLevel]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyGestureID], eventAttributes[MMEEventKeyGestureID]);
}

- (void)testEnqueueMapDragEndEvent {
    MMEEventsManager *eventsManager = [MMEEventsManager sharedManager];
    MMENSDateWrapperFake *dateWrapperFake = [[MMENSDateWrapperFake alloc] init];
    dateWrapperFake.testDate = [NSDate dateWithTimeIntervalSince1970:42424242];
    eventsManager.dateWrapper = dateWrapperFake;
    eventsManager.metricsEnabledInSimulator = YES;
    [eventsManager resumeMetricsCollection];
    
    NSDictionary *eventAttributes = @{MMEEventKeyLatitude: @(-10),
                                      MMEEventKeyLongitude: @(10),
                                      MMEEventKeyZoomLevel: @(24)};
    [eventsManager enqueueEventWithName:MMEEventTypeMapDragEnd attributes:eventAttributes];
    
    MMEEvent *event = eventsManager.eventQueue.firstObject;
    XCTAssertEqualObjects(event.name, MMEEventTypeMapDragEnd);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyEvent], MMEEventTypeMapDragEnd);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyCreated], @"1971-05-07T00:30:42.000+0000");
    XCTAssertNotNil(event.attributes[MMEEventKeyOrientation]);
    XCTAssertTrue([event.attributes.allKeys containsObject:MMEEventKeyWifi]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyLatitude], eventAttributes[MMEEventKeyLatitude]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyLongitude], eventAttributes[MMEEventKeyLongitude]);
    XCTAssertEqualObjects(event.attributes[MMEEventKeyZoomLevel], eventAttributes[MMEEventKeyZoomLevel]);
}

- (void)testUnknownEvent {
    MMEEventsManager *eventsManager = [MMEEventsManager sharedManager];
    [eventsManager enqueueEventWithName:@"unkonwn" attributes:@{}];
    XCTAssertEqual(eventsManager.eventQueue.count, 0);
}

- (void)testNavigationEvents {
    MMEEventsManager *eventsManager = [MMEEventsManager sharedManager];
    [eventsManager enqueueEventWithName:MMEEventTypeNavigationArrive attributes:@{}];
    [eventsManager enqueueEventWithName:MMEEventTypeNavigationDepart attributes:@{}];
    [eventsManager enqueueEventWithName:MMEEventTypeNavigationCancel attributes:@{}];
    [eventsManager enqueueEventWithName:MMEEventTypeNavigationFeedback attributes:@{}];
    [eventsManager enqueueEventWithName:MMEEventTypeNavigationReroute attributes:@{}];
    [eventsManager enqueueEventWithName:[NSString stringWithFormat:@"%@.anything", MMENavigationEventPrefix] attributes:@{}];
    XCTAssertEqual(eventsManager.eventQueue.count, 6);
}

- (CLLocation *)location {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(10, 10);
    CLLocationDistance altitude = 100;
    CLLocationAccuracy horizontalAccuracy = 42;
    CLLocationAccuracy verticalAccuracy = 24;
    CLLocationDirection course = 99;
    CLLocationSpeed speed = 102;
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];
    return [[CLLocation alloc] initWithCoordinate:coordinate
                                         altitude:altitude
                               horizontalAccuracy:horizontalAccuracy
                                 verticalAccuracy:verticalAccuracy
                                           course:course
                                            speed:speed
                                        timestamp:timestamp];
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
