#import <XCTest/XCTest.h>
#import <MapboxMobileEvents/>

@interface MMETestHostUITests : XCTestCase

@end

@implementation MMETestHostUITests

- (void)setUp {
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPatience {
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"42"];
    
    [self leaksTest];

    [self expectationForPredicate:exists evaluatedWithObject:nil handler:nil];
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)leaksTest {
    self.locationManager  = [[CLLocationManager alloc] init];
    [self.locationManager requestAlwaysAuthorization];
    // Do any additional setup after loading the view.
    [MMEEventsManager.sharedManager initializeWithAccessToken:@"pk.eyJ1IjoicmNsZWVkZXYiLCJhIjoiY2plaXFraWZ5MXFsejJxbGloZjJ0NGxrbiJ9.7hPRHHLNZLEhREJ963veeQ" userAgentBase:@"rcleetest" hostSDKVersion:@"0.0.0"];
    MMEEventsManager.sharedManager.baseURL = [NSURL URLWithString:@"https://api-events-staging.tilestream.net"];
    [MMEEventsManager.sharedManager sendTurnstileEvent];
    MMEEventsManager.sharedManager.skuId = @"00";
    [MMEEventsManager.sharedManager flush];
    
    
    [MMEEventsManager.sharedManager initializeWithAccessToken:@"pk.eyJ1IjoicmNsZWVkZXYiLCJhIjoiY2plaXFraWZ5MXFsejJxbGloZjJ0NGxrbiJ9.7hPRHHLNZLEhREJ963veeQ" userAgentBase:@"rcleetest" hostSDKVersion:@"0.0.0"];
    MMEEventsManager.sharedManager.baseURL = [NSURL URLWithString:@"https://api-events-staging.tilestream.net"];
    [MMEEventsManager.sharedManager sendTurnstileEvent];
    MMEEventsManager.sharedManager.skuId = @"00";
    [MMEEventsManager.sharedManager flush];
}

@end
