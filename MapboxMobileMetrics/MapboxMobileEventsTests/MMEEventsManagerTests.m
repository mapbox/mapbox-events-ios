#import <XCTest/XCTest.h>

#import "MMEEventsManager.h"
#import "MMEEvent.h"
#import "MMELocationManager.h"
#import "MMEConstants.h"
#import "MMEUniqueIdentifier.h"
#import "MMECommonEventData.h"

#import "NSDateFormatter+MMEMobileEvents.h"
#import "CLLocation+MMEMobileEvents.h"

@interface MMEEventsManagerTests : XCTestCase

@end

@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

@property (nonatomic) MMELocationManager *locationManager;
@property (nonatomic) NS_MUTABLE_ARRAY_OF(MGLMapboxEventAttributes *) *eventQueue;
@property (nonatomic) MMEUniqueIdentifier *uniqueIdentifer;
@property (nonatomic) MMECommonEventData *commonEventData;

@end

@implementation MMEEventsManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testAsADelegateForLocationManagerDidUpdateLocations {
    MMEEventsManager *eventsManager = [[MMEEventsManager alloc] init];

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(10, 10);
    CLLocationDistance altitude = 100;
    CLLocationAccuracy horizontalAccuracy = 42;
    CLLocationAccuracy verticalAccuracy = 24;
    CLLocationDirection course = 99;
    CLLocationSpeed speed = 102;
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:altitude
                                               horizontalAccuracy:horizontalAccuracy
                                                 verticalAccuracy:verticalAccuracy
                                                           course:course
                                                            speed:speed
                                                        timestamp:timestamp];

    MMECommonEventData *dataStub = [[MMECommonEventData alloc] init];
    dataStub.iOSVersion = @"iOS-version";
    eventsManager.commonEventData = dataStub;

    NSDateFormatter *dateFormatter = [NSDateFormatter rfc3339DateFormatter];

    [eventsManager locationManager:nil didUpdateLocations:@[location]];

    MGLMutableMapboxEventAttributes *attributes = [NSMutableDictionary dictionary];
    attributes[MMEEventKeyEvent] = MMEEventTypeLocation;
    attributes[MMEEventKeySource] = MMEEventSource;
    attributes[MMEEventKeySessionId] = [[MMEUniqueIdentifier alloc] init].rollingInstanceIdentifer;
    attributes[MMEEventKeyOperatingSystem] = dataStub.iOSVersion;
    attributes[MMEEventKeyApplicationState] = [dataStub applicationState];
    attributes[MMEEventKeyCreated] = [dateFormatter stringFromDate:timestamp];
    attributes[MMEEventKeyLatitude] = @([location latitudeRoundedWithPrecision:7]);
    attributes[MMEEventKeyLongitude] = @([location longitudeRoundedWithPrecision:7]);
    attributes[MMEEventKeyAltitude] = @([location roundedAltitude]);
    attributes[MMEEventHorizontalAccuracy] = @(horizontalAccuracy);

    NSDictionary *event = eventsManager.eventQueue.firstObject;

    XCTAssertEqualObjects(event, attributes);
}

@end
