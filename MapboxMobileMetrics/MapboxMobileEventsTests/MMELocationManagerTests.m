#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>

#import "MMELocationManager.h"
#import "MMECLLocationManagerWrapper.h"

#import "MMECLLocationManagerWrapperFake.h"

@interface MMELocationManager (Test)

@property (nonatomic) MMECLLocationManagerWrapperFake *locationManager;

@end

@interface MMELocationManagerTests : XCTestCase

@end

@implementation MMELocationManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartUpdatingLocation {
    MMELocationManager *locationManager = [[MMELocationManager alloc] init];
    MMECLLocationManagerWrapperFake *locationManagerWrapper = [[MMECLLocationManagerWrapperFake alloc] init];

    locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedAlways;
    locationManager.locationManager = locationManagerWrapper;
    [locationManager startUpdatingLocation];
    XCTAssert(locationManager.isUpdatingLocation, @"locationManager should be updating location");
}

@end
