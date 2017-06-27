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

#import "NSDateFormatter+MMEMobileEvents.h"
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
    
    NSDateFormatter *dateFormatter = [NSDateFormatter rfc3339DateFormatter];
    
    CLLocation *location = [self location];
    [[MMEEventsManager sharedManager] locationManager:nil didUpdateLocations:@[location]];
    
    MGLMutableMapboxEventAttributes *attributes = [NSMutableDictionary dictionary];
    attributes[MMEEventKeyEvent] = MMEEventTypeLocation;
    attributes[MMEEventKeySource] = MMEEventSource;
    attributes[MMEEventKeySessionId] = [[MMEUniqueIdentifierFake alloc] init].rollingInstanceIdentifer;
    attributes[MMEEventKeyOperatingSystem] = dataStub.iOSVersion;
    attributes[MMEEventKeyApplicationState] = [dataStub applicationState];
    attributes[MMEEventKeyCreated] = [dateFormatter stringFromDate:location.timestamp];
    attributes[MMEEventKeyLatitude] = @([location latitudeRoundedWithPrecision:7]);
    attributes[MMEEventKeyLongitude] = @([location longitudeRoundedWithPrecision:7]);
    attributes[MMEEventKeyAltitude] = @([location roundedAltitude]);
    attributes[MMEEventHorizontalAccuracy] = @(location.horizontalAccuracy);
    
    XCTAssertTrue([apiClient received:@selector(postEvents:completionHandler:)]);
    
    NSArray *arguments = [apiClient.argumentsBySelector[[NSValue valueWithPointer:@selector(postEvents:completionHandler:)]] firstObject];
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

- (void)testSendTurnstileEventWithSuccess {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    NSString *hostSDKVersion = @"host-sdk-1";
    MMEEventsManager *manager = [MMEEventsManager sharedManager];
    [manager initializeWithAccessToken:accessToken userAgentBase:userAgentBase hostSDKVersion:hostSDKVersion];
    
    MMEAPIClientFake *apiClient = [[MMEAPIClientFake alloc] init];
    apiClient.userAgentBase = @"user-agent-base";
    apiClient.accessToken = @"access-token";
    manager.apiClient = apiClient;
    
    XCTAssertNil(manager.nextTurnstileSendDate);
    XCTAssertNotNil(manager.commonEventData.vendorId);
    
    [manager sendTurnstileEvent];
    XCTAssertTrue([apiClient received:@selector(postEvent:completionHandler:)]);
    
    [apiClient completePostingEventsWithError:nil];
    XCTAssertNotNil(manager.nextTurnstileSendDate);
    
    // Any subsequent calls to send more turnstile events are no-ops
    [apiClient resetReceivedSelectors];
    [manager sendTurnstileEvent];
    XCTAssertFalse([apiClient received:@selector(postEvent:completionHandler:)]);
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
