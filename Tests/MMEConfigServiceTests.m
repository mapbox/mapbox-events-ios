#import <XCTest/XCTest.h>
#import "MMEConfigService.h"
#import "MMEMockEventConfig.h"
#import "MMEServiceFixture.h"
#import "MMEAPIClient.h"
#import "MMENSURLSessionWrapper.h"
#import "EventConfigStubProtocol.h"

@interface MMEConfigServiceTests : XCTestCase

@end

@implementation MMEConfigServiceTests

- (void)testConfigPolling {

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = @[EventConfigStubProtocol.self];
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithConfiguration:sessionConfiguration];
    MMEMockEventConfig* eventConfig = MMEMockEventConfig.oneSecondConfigUpdate;
    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:eventConfig session:session];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Config Polling"];
    __block int configLoadCount;

    MMEConfigService* service = [[MMEConfigService alloc] init:eventConfig
                                                              client:client
                                                        onConfigLoad:^(MMEConfig * _Nonnull config) {
        configLoadCount +=1;

        // Expect Service to Poll at least 2 times based on the Mock Event Config specifying 1s interval
        if (configLoadCount >= 2) {
            [expectation fulfill];
        }
    }];

    [service startUpdates];
    [self waitForExpectations:@[expectation] timeout:3];
}

@end
