#import <XCTest/XCTest.h>
#import "MMEMockEventConfig.h"
#import "MMENSURLRequestFactory.h"
#import "MMEEvent.h"

@interface MMENSURLRequestFactoryTests : XCTestCase
@property (nonatomic, strong) MMENSURLRequestFactory* factory;

@end

@implementation MMENSURLRequestFactoryTests

- (void)setUp {
    self.factory = [[MMENSURLRequestFactory alloc] initWithConfig: [MMEMockEventConfig oneSecondConfigUpdate]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInitRequest {
    NSURLRequest* request = [self.factory urlRequestWithMethod:@"GET"
                                                       baseURL:[NSURL URLWithString:@"https://mapbox.com"]
                                                          path:@"hi/there"
                                             additionalHeaders:@{@"help":@"me"}
                                                      httpBody:NSData.new];

    XCTAssertEqualObjects(request.HTTPMethod, @"GET");
    XCTAssertEqualObjects(request.URL.absoluteString, @"https://mapbox.com/hi/there?access_token=access-token");
    NSDictionary<NSString*, NSString*>* headers = @{
        @"Content-Type": @"application/json",
        @"User-Agent": @"<LegacyUserAgent>",
        @"X-Mapbox-Agent": @"<UserAgent>",
        @"help":@"me"
    };
    XCTAssertEqualObjects(request.allHTTPHeaderFields, headers);
    XCTAssertEqual(request.HTTPBody.length, 0);
}

- (void)testPostEventURLRequest {
    NSError* error = nil;
    MMEEvent* event = [MMEEvent turnstileEventWithConfiguration:[[MMEMockEventConfig alloc] init] skuID:nil];
    NSURLRequest* request = [self.factory requestForEvents:@[event] error:&error];
    NSDictionary<NSString*, NSString*>* headers = @{
        @"Content-Type": @"application/json",
        @"User-Agent":  @"<LegacyUserAgent>",
        @"X-Mapbox-Agent": @"<UserAgent>"
    };

    XCTAssertEqualObjects(@"https://events.mapbox.com/events/v2?access_token=access-token", request.URL.absoluteString);
    XCTAssertEqualObjects(headers, request.allHTTPHeaderFields);
    XCTAssertNotNil(request.HTTPBody);
}

- (void)testGetConfigURLRequest {
    NSURLRequest* request = [self.factory requestForConfiguration];
    NSDictionary<NSString*, NSString*>* headers = @{
        @"Content-Type": @"application/json",
        @"User-Agent":  @"<LegacyUserAgent>",
        @"X-Mapbox-Agent": @"<UserAgent>"
    };

    XCTAssertEqualObjects(@"https://config.mapbox.com/events-config?access_token=access-token", request.URL.absoluteString);
    XCTAssertEqualObjects(headers, request.allHTTPHeaderFields);
    XCTAssertNil(request.HTTPBody);
}

@end
