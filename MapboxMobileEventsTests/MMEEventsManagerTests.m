#import <XCTest/XCTest.h>

#import "MMEEventsManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEConstants.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"
#import "MMEAPIClient.h"
#import "MMEAPIClientFake.h"
#import "MMEEventsConfiguration.h"
#import "MMETimerManagerFake.h"
#import "MMEUniqueIdentifierFake.h"
#import "MMEUIApplicationWrapper.h"
#import "MMEUIApplicationWrapperFake.h"
#import "MMECLLocationManagerWrapper.h"
#import "MMECLLocationManagerWrapperFake.h"
#import "MMELocationManagerFake.h"
#import "MMENSDateWrapper.h"
#import "MMENSDateWrapperFake.h"

#import "CLLocation+MMEMobileEvents.h"

@interface MMEEventsManagerTests : XCTestCase
@end

@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) id<MMEAPIClient> apiClient;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) MMEEventsConfiguration *configuration;
@property (nonatomic) MMETimerManager *timerManager;
@property (nonatomic) id<MMECLLocationManagerWrapper> locationManagerWrapper;
@property (nonatomic) id<MMEUIApplicationWrapper> application;\
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) MMENSDateWrapper *dateWrapper;

- (void)pauseMetricsCollection;
- (void)resumeMetricsCollection;

@end

@interface MMEAPIClient (Tests)

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;

@end


@implementation MMEEventsManagerTests

- (void)setUp {
    [super setUp];
    
    [MMEEventsManager sharedManager].uniqueIdentifer = [[MMEUniqueIdentifierFake alloc] init];
    [[[MMEEventsManager sharedManager] eventQueue] removeAllObjects];
    
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = 1000;
    [MMEEventsManager sharedManager].configuration = configuration;
}

// TODO: Add test for background task
- (void)testDisableLocationMetrics {
    XCTAssertTrue(NO);
}

// TODO: Add test for background task
- (void)testPauseOrResumeMetricsCollectionBackgroundTaskWithWhenInUsePermissionInBackground {
    XCTAssertTrue(NO);
}

// TODO: Add test for background task
- (void)testPauseOrResumeMetricsCollectionWhenMetricsCanBeCollectedInBackgroundWithInUsePermissionsOnly {
    XCTAssertTrue(NO);
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

@end
