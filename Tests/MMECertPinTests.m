@import XCTest;
@import Foundation;
@import Security;

#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMEAPIClientFake.h"
#import "MMECertPin.h"
#import "MMECommonEventData.h"
#import "MMEEvent.h"
#import "MMEEventsManager.h"
#import "MMENSURLSessionWrapper.h"

#import "MMERunningLock.h"
#import "MMEServiceFixture.h"

#import "NSUserDefaults+MMEConfiguration.h"

@interface MMENSURLSessionWrapper (MMECertPinTests)

@property (nonatomic) MMECertPin *certPin;

@end

// MARK: -

@interface MMECertPin (Tests)
@property (nonatomic) NSURLSessionAuthChallengeDisposition lastAuthChallengeDisposition;

- (NSData *)getPublicKeyDataFromCertificate_legacy_ios:(SecCertificateRef)certificate;

@end

// MARK: -

@interface MMEAPIClient ()
@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;

@end


// MARK: -

@interface MMECertPinTests : XCTestCase
@property(nonatomic) MMENSURLSessionWrapper *sessionWrapper;
@property(nonatomic) MMEEventsConfiguration *configuration;
@property(nonatomic) NSArray *blacklistFake;
@property(nonatomic) MMEAPIClient<MMEAPIClient> *apiClient;

@end

// MARK: -

@implementation MMECertPinTests

- (void)setUp {
    [MMEEventsManager.sharedManager initializeWithAccessToken:@"test-access-token" userAgentBase:@"user-agent-base-sucks" hostSDKVersion:@"-NaN"];

    self.apiClient = MMEEventsManager.sharedManager.apiClient;
}

- (void)test001_checkCNHashCount {
    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssert(cnHashes.count ==54);
}

-(void)test002_checkCOMHashCount {
    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(comHashes.count ==54);
}
    
-(void)test003_countCNHashesWithBlacklist {
    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
    XCTAssertNil(configError);

    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssert(cnHashes.count == 53);
}
            
-(void)test004_countCOMHashesWithBlacklist {
    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
    XCTAssertNil(configError);

    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(comHashes.count == 53);
}

@end
