@import XCTest;
@import Foundation;
@import Security;

#import <CommonCrypto/CommonDigest.h>
#import "MMECertPin.h"
#import "MMEMockEventConfig.h"
#import "MMENSURLSessionWrapper.h"

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

@end

// MARK: -

@implementation MMECertPinTests

- (void)setUp {
    // TODO: Validate MMECertPin Responsibilities
    NSURLSessionConfiguration* sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration;
    MMEMockEventConfig* eventConfig = [[MMEMockEventConfig alloc] init];
    MMECertPin* certPin = [[MMECertPin alloc] initWithConfig:eventConfig];
//    dispatch_queue_t queue = dispatch_queue_create(@"com.mapbox.tests.CertPin", DISPATCH_QUEUE_SERIAL)
    dispatch_queue_t queue = dispatch_queue_create(
                                                   [[NSString stringWithFormat:@"com.mapbox.tests.%@", NSStringFromClass([self class])] UTF8String], DISPATCH_QUEUE_SERIAL
                                                   );
    
    [[MMENSURLSessionWrapper alloc] initWithConfiguration:sessionConfiguration
                                          completionQueue:queue
                                                  certPin:certPin];
}


<<<<<<< HEAD

=======
-(void)testCheckCOMHashCount {
    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(comHashes.count == 54);
}
    
-(void)testCountCNHashesWithBlacklist {
    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
    XCTAssertNil(configError);

    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssert(cnHashes.count == 53);
}
            
-(void)testCountCOMHashesWithBlacklist {
    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-crl"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // fetch the config fixture
    XCTAssertNil(configError);

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
>>>>>>> [Tests] Get Tests Running


@end
