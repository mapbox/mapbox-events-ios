#import <XCTest/XCTest.h>

#import "MMECertPin.h"
#import "MMEAPIClient.h"
#import "MMENSURLSessionWrapper.h"
#import "MMECommonEventData.h"
#import "MMEEvent.h"


/*
    Note:
 
    We test certificate pinning logic with a real network request just because we cannot manually make a fake `NSURLAuthenticationChallenge` object.
 
    Once you want to create a fake `NSURLAuthenticationChallenge` object, the sub property `NSURLProtectionSpace`
    protectionSpace, will return a nil `SecTrustRef` serverTrust forever.
 
    It seems that is not as same as Apple's documentation:
    `Nil if the authenticationMethod is not NSURLAuthenticationMethodServerTrust`.
    See: https://developer.apple.com/documentation/foundation/nsurlprotectionspace/1409926-servertrust?language=objc
 
     This is why we can't simulate this behavior.
 
 */

@interface MMECertPin (CertPinTest)

@property (nonatomic) NSURLSessionAuthChallengeDisposition lastAuthChanllengeDisposition;

@end

@interface MMENSURLSessionWrapper (CertPinTest)

@property (nonatomic) MMECertPin *certPin;

@end

@interface MMEAPIClient (CertPinTest)

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;

@end


@interface MMEAPIClientCertPinTests : XCTestCase

@end

@implementation MMEAPIClientCertPinTests

- (void)setUp {
}

- (void)tearDown {
    
}

- (void)testPostASingleEvent {
    
    MMEAPIClient *apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                                             userAgentBase:@"user-agent-base"
                                                                            hostSDKVersion:@"host-sdk-1"];
    
    MMENSURLSessionWrapper *sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
    apiClient.sessionWrapper = sessionWrapper;
    
    MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
    commonEventData.vendorId = @"vendor-id";
    commonEventData.model = @"model";
    commonEventData.iOSVersion = @"1";
    commonEventData.scale = 42;
    
    MMEEvent *event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
    
    XCTestExpectation* exception = [self expectationWithDescription:@"post a single event"];
    
    [apiClient postEvent:event completionHandler:^(NSError * _Nullable error){
        [exception fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(sessionWrapper.certPin.lastAuthChanllengeDisposition, NSURLSessionAuthChallengeUseCredential, @"Post a single event should use credential");
    }];
}

- (void)testGetConfigurationWithExcludedDomain {
    MMEAPIClient *apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                          userAgentBase:@"user-agent-base"
                                                         hostSDKVersion:@"host-sdk-1"];;
    __block MMENSURLSessionWrapper *sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
    apiClient.sessionWrapper = sessionWrapper;
    
    XCTestExpectation* exception = [self expectationWithDescription:@"post a single event"];
    
    [apiClient getConfigurationWithCompletionHandler:^(NSError * _Nullable error, NSData * _Nullable data) {
        [exception fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(sessionWrapper.certPin.lastAuthChanllengeDisposition, NSURLSessionAuthChallengePerformDefaultHandling, @"Get configuration with excluded domain should use default handling");
    }];
    
}


@end
