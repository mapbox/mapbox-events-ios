#import <XCTest/XCTest.h>
#import "CLLocationManager+MMEMobileEvents.h"

// MARK: - Mock Classes


@interface MockCLLocationManagerDenied : CLLocationManager

@end

@implementation MockCLLocationManagerDenied

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusDenied;
}

@end

@interface MockCLLocationManagerRestricted : CLLocationManager

@end

@implementation MockCLLocationManagerRestricted

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusRestricted;
}

@end

@interface MockCLLocationManagerNotDetermined : CLLocationManager

@end

@implementation MockCLLocationManagerNotDetermined

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusNotDetermined;
}

@end

@interface MockCLLocationManagerAlways : CLLocationManager

@end

@implementation MockCLLocationManagerAlways

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusAuthorizedAlways;
}

@end

@interface MockCLLocationManagerWhenInUse : CLLocationManager

@end

@implementation MockCLLocationManagerWhenInUse

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusAuthorizedWhenInUse;
}

@end

@interface MockCLLocationManagerUnknown : CLLocationManager

@end

@implementation MockCLLocationManagerUnknown

+ (CLAuthorizationStatus)authorizationStatus {
    return (CLAuthorizationStatus)@"foo";
}

@end

// MARK: - Tests
@interface CLLocationManagerTests : XCTestCase

@end

@implementation CLLocationManagerTests

-(void)testMMEStatus {
    XCTAssertEqualObjects([MockCLLocationManagerDenied mme_authorizationStatusString], @"denied");
    XCTAssertEqualObjects([MockCLLocationManagerRestricted mme_authorizationStatusString], @"restricted");
    XCTAssertEqualObjects([MockCLLocationManagerNotDetermined mme_authorizationStatusString], @"notDetermined");
    XCTAssertEqualObjects([MockCLLocationManagerAlways mme_authorizationStatusString], @"always");
    XCTAssertEqualObjects([MockCLLocationManagerWhenInUse mme_authorizationStatusString], @"whenInUse");
    XCTAssertEqualObjects([MockCLLocationManagerUnknown mme_authorizationStatusString], @"unknown");
}

@end


