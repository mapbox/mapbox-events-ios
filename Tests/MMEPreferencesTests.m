#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConfig.h"
#import "MMEPreferences.h"

@interface MMEPreferencesTests : XCTestCase

@end

@implementation MMEPreferencesTests

- (void)testExpectedCNHashCount {
    NSArray* chinaHashes = NSUserDefaults.mme_chinaPublicKeys;
    XCTAssertEqual(chinaHashes.count, 54);
}

-(void)testExpectedCOMHashCount {
    NSArray* commercialHashes = NSUserDefaults.mme_comPublicKeys;
    XCTAssertEqual(commercialHashes.count, 54);
}

// Ensure Blacklist Filtering is working correctly (China)
-(void)testCountChinaWithBlackList {

    NSError* error = nil;
    NSDictionary* dictionary = @{
        @"crl": @[
                @"i/4rsupujT8Ww/2yIGJ3wb6R7GDw2FHPyOM5sWh87DQ=",
                @"+1CHLRDE6ehp61cm8+NDMvd32z0Qc4bgnZRLH0OjE94="
        ]
    };
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:dictionary error:&error];
    MMEPreferences* preferences = [[MMEPreferences alloc] init];
    [preferences updateWithConfig:config];
    NSArray *hashes = preferences.certificatePinningConfig[@"events.mapbox.cn"];
    XCTAssertEqual(hashes.count, 53);
}

// Ensure Blacklist Filtering is working correctly (China)
-(void)testCountCommercialHashesWithBlacklist {
    NSError* error = nil;
    NSDictionary* dictionary = @{
        @"crl": @[
                @"i/4rsupujT8Ww/2yIGJ3wb6R7GDw2FHPyOM5sWh87DQ=",
                @"+1CHLRDE6ehp61cm8+NDMvd32z0Qc4bgnZRLH0OjE94="
        ]
    };
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:dictionary error:&error];
    MMEPreferences* preferences = [[MMEPreferences alloc] init];
    [preferences updateWithConfig:config];

    NSArray *hashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    XCTAssert(hashes.count == 53);
}

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
