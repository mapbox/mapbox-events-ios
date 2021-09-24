@import XCTest;
@import Foundation;
@import Security;

#import <CommonCrypto/CommonDigest.h>

#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMECertPin.h"
#import "MMECommonEventData.h"
#import "MMEEvent.h"
#import "MMEEventsManager.h"
#import "MMENSURLSessionWrapper.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"

#import "MMEAPIClientFake.h"
#import "MMEServiceFixture.h"
#import "MMEBundleInfoFake.h"


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
    [MMEEventsManager.sharedManager initializeWithAccessToken:@"test-access-token" userAgentBase:@"user-agent-base-sucks" hostSDKVersion:@"1.2.3"];
    
    // reset configuration, set a test access token
    [NSUserDefaults mme_resetConfiguration];
    NSUserDefaults.mme_configuration.mme_accessToken = @"test-access-token";

    // inject our config service URL from the MMEService Fixtures
    NSMutableDictionary *infoDictionary = NSBundle.mainBundle.infoDictionary.mutableCopy;
    infoDictionary[MMEConfigServiceURL] = MMEServiceFixture.serviceURL;
    MMEBundleInfoFake *fakeBundle = [MMEBundleInfoFake new];
    fakeBundle.infoDictionaryFake = infoDictionary;
    NSBundle.mme_mainBundle = fakeBundle;

    self.apiClient = MMEEventsManager.sharedManager.apiClient;
    self.sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
}

- (void)test001_checkCNHashCount {
    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssert(cnHashes.count == 56);
}

-(void)test002_checkCOMHashCount {
    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(comHashes.count == 60);
}

#if !SWIFT_PACKAGE
// Disabled when testing as a Swift Package because resources was introduced in Swift 5.3 and we only require 5.2
-(void)test003_countCNHashesWithBlacklist {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
    XCTAssertNil(configError);

    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssert(cnHashes.count == 55);
}
            
-(void)test004_countCOMHashesWithBlacklist {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
    XCTAssertNil(configError);

    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(comHashes.count == 59);
}
#endif

-(void)test005_validateCNHashes {
    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    NSMutableArray *invalidHashes = [[NSMutableArray alloc] init];
    
    for (NSString *publicKeyHash in cnHashes) {
        NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:publicKeyHash options:(NSDataBase64DecodingOptions)0];
        if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){
            // The subject public key info hash doesn't have a valid size
            [invalidHashes addObject:publicKeyHash];
        }
    }
    XCTAssert(invalidHashes.count == 0);
}

-(void)test006_validateCOMHashes {
    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    NSMutableArray *invalidHashes = [[NSMutableArray alloc] init];
    
    for (NSString *publicKeyHash in comHashes) {
        NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:publicKeyHash options:(NSDataBase64DecodingOptions)0];
        if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){
            // The subject public key info hash doesn't have a valid size
            [invalidHashes addObject:publicKeyHash];
        }
    }
    XCTAssert(invalidHashes.count == 0);
}

-(void)test007_pinEventsMapboxCom {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should have status 200 and pass pin validation."];
        
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://events.mapbox.com"]];

    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"NSURLRequest failed with error: %@", error);
        } else {
            [expectation fulfill];
        }
    }];

    [self waitForExpectations:@[expectation] timeout:30];
}

@end
