@import XCTest;
@import Foundation;
@import Security;

#import <CommonCrypto/CommonDigest.h>

#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMEAPIClientFake.h"
#import "MMECertPin.h"
#import "MMEEvent.h"
#import "MMEEventsManager.h"
#import "MMEEventsManager_Private.h"
#import "MMENSURLSessionWrapper.h"

#import "MMEServiceFixture.h"
#import "MMEBundleInfoFake.h"

#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEPreferences.h"
#import "MMELogger.h"
#import "MMEMetricsManager.h"
#import "MMEUniqueIdentifier.h"
#import "MMEUIApplicationWrapperFake.h"
#import "MMEDispatchManager.h"

@interface MMENSURLSessionWrapper (MMECertPinTests)

@property (nonatomic) MMECertPin *certPin;

@end

// MARK: -

@interface MMECertPin (Tests)
@property (nonatomic) NSURLSessionAuthChallengeDisposition lastAuthChallengeDisposition;

- (NSData *)getPublicKeyDataFromCertificate_legacy_ios:(SecCertificateRef)certificate;

@end

// MARK: -

@interface MMECertPinTests : XCTestCase
@property(nonatomic) MMENSURLSessionWrapper *sessionWrapper;
@property(nonatomic) MMEEventsConfiguration *configuration;
@property(nonatomic) NSArray *blacklistFake;
@property(nonatomic) MMEAPIClient<MMEAPIClient> *apiClient;
@property(nonatomic, strong) MMEEventsManager* eventsManager;

@end

// MARK: -

@implementation MMECertPinTests

- (void)setUp {
    MMELogger* logger = [[MMELogger alloc] init];

    // Initialize With Default Preferences
    // Use new Bundle, as well as separate UserDefaults instance to ensure main bundle Info.plist
    // does not interfear with test
    NSMutableDictionary *infoDictionary = NSBundle.mainBundle.infoDictionary.mutableCopy;
    infoDictionary[MMEConfigServiceURL] = MMEServiceFixture.serviceURL;
    MMEBundleInfoFake *fakeBundle = [MMEBundleInfoFake new];

    MMEPreferences* preferences = [[MMEPreferences alloc] initWithBundle:fakeBundle
                                                               dataStore:NSUserDefaults.mme_configuration];

    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithLogger:logger config:preferences];


    self.eventsManager = [[MMEEventsManager alloc] initWithPreferences:preferences
                                                      uniqueIdentifier:[[MMEUniqueIdentifier alloc] initWithTimeInterval:preferences.identifierRotationInterval]
                                                           application:[[MMEUIApplicationWrapperFake alloc] init]
                                                        metricsManager:metricsManager
                                                       dispatchManager:[[MMEDispatchManager alloc] init]
                                                                logger:logger];

    [self.eventsManager startEventsManagerWithToken:@"test-access-token"
                                      userAgentBase:@"user-agent-base-sucks"
                                     hostSDKVersion:@"1.2.3"];
    self.apiClient = self.eventsManager.apiClient;
}

- (void)testCheckCNHashCount {
    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssert(cnHashes.count == 54);
}

-(void)testCheckCOMHashCount {
    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(comHashes.count == 54);
}

// TODO: - Disable Until Config behavior is Determinant
// This is currently flaky b/c upon testing, this blacklist is empty
//-(void)test003_countCNHashesWithBlacklist {
//    NSError *configError = nil;
//    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
//    [self.apiClient startGettingConfigUpdates];
//    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
//    XCTAssertNil(configError);
//
//    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
//    XCTAssert(cnHashes.count == 53);
//}
//            
//-(void)test004_countCOMHashesWithBlacklist {
//    NSError *configError = nil;
//    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
//    [self.apiClient startGettingConfigUpdates];
//    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
//    XCTAssertNil(configError);
//
//    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
//    XCTAssert(comHashes.count == 53);
//}

-(void)testValidateCNHashes {
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

-(void)testValidateCOMHashes {
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

@end
