#import <XCTest/XCTest.h>
#import "MMEConfigService.h"
#import "MMEMockEventConfig.h"
#import "MMEServiceFixture.h"

@interface MMEConfigServiceTests : XCTestCase

@end

@implementation MMEConfigServiceTests

- (void)testConfigPolling {

    id <MMEEventConfigProviding> config = [MMEMockEventConfig oneSecondConfigUpdate];
    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:config];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Config Polling"];
    __block int configLoadCount;

    MMEConfigService* service = [[MMEConfigService alloc] init:config
                                                              client:client
                                                        onConfigLoad:^(MMEConfig * _Nonnull config) {
        configLoadCount +=1;
        if (configLoadCount >= 2) {
            [expectation fulfill];
        }
    }];

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-all"];
    [service startUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
}

@end
