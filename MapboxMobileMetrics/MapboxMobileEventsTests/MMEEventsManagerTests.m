#import <XCTest/XCTest.h>

#import "MMEEventsManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEConstants.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"
#import "MMEAPIClient.h"
#import "MMEAPIClientFake.h"

#import "NSDateFormatter+MMEMobileEvents.h"
#import "CLLocation+MMEMobileEvents.h"

@interface MMEEventsManagerTests : XCTestCase
@end

@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

@property (nonatomic) MMELocationManager *locationManager;
@property (nonatomic) id<MMEAPIClient> apiClient;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MGLMapboxEventAttributes *) *eventQueue;
@property (nonatomic) MMEUniqueIdentifier *uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) NSDate *nextTurnstileSendDate;

@end

@interface MMEAPIClient (Tests)

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;

@end


@implementation MMEEventsManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testAsADelegateForLocationManagerDidUpdateLocations {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    
    [[MMEEventsManager sharedManager] initializeWithAccessToken:accessToken userAgentBase:userAgentBase];
    
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.accessToken, accessToken);
    XCTAssertEqual([MMEEventsManager sharedManager].apiClient.userAgentBase, userAgentBase);

//    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(10, 10);
//    CLLocationDistance altitude = 100;
//    CLLocationAccuracy horizontalAccuracy = 42;
//    CLLocationAccuracy verticalAccuracy = 24;
//    CLLocationDirection course = 99;
//    CLLocationSpeed speed = 102;
//    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];
//
//    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
//                                                         altitude:altitude
//                                               horizontalAccuracy:horizontalAccuracy
//                                                 verticalAccuracy:verticalAccuracy
//                                                           course:course
//                                                            speed:speed
//                                                        timestamp:timestamp];

//    MMECommonEventData *dataStub = [[MMECommonEventData alloc] init];
//    dataStub.iOSVersion = @"iOS-version";
//    eventsManager.commonEventData = dataStub;
//
//    NSDateFormatter *dateFormatter = [NSDateFormatter rfc3339DateFormatter];
//
//    [eventsManager locationManager:nil didUpdateLocations:@[location]];
//
//    MGLMutableMapboxEventAttributes *attributes = [NSMutableDictionary dictionary];
//    attributes[MMEEventKeyEvent] = MMEEventTypeLocation;
//    attributes[MMEEventKeySource] = MMEEventSource;
//    attributes[MMEEventKeySessionId] = [[MMEUniqueIdentifier alloc] init].rollingInstanceIdentifer;
//    attributes[MMEEventKeyOperatingSystem] = dataStub.iOSVersion;
//    attributes[MMEEventKeyApplicationState] = [dataStub applicationState];
//    attributes[MMEEventKeyCreated] = [dateFormatter stringFromDate:timestamp];
//    attributes[MMEEventKeyLatitude] = @([location latitudeRoundedWithPrecision:7]);
//    attributes[MMEEventKeyLongitude] = @([location longitudeRoundedWithPrecision:7]);
//    attributes[MMEEventKeyAltitude] = @([location roundedAltitude]);
//    attributes[MMEEventHorizontalAccuracy] = @(horizontalAccuracy);
//
//    NSDictionary *event = eventsManager.eventQueue.firstObject;
//    
//    XCTAssertEqualObjects(event, attributes);
}

- (void)testSendTurnstileEventWithSuccess {
    NSString *accessToken = @"access-token";
    NSString *userAgentBase = @"UA-base";
    MMEEventsManager *manager = [MMEEventsManager sharedManager];
    [manager initializeWithAccessToken:accessToken userAgentBase:userAgentBase];
    
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

@end
