#import <XCTest/XCTest.h>
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConfig.h"

@interface MMEConfigTests : XCTestCase

@end

@implementation MMEConfigTests

- (void)testInitWithInvalidCRL {
    NSDictionary *jsonDict = @{
        @"crl": @[@"not-a-key-hash"]
    };
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&error];
    XCTAssertNil(config);
    XCTAssertNotNil(error);
}

// An Certificate Revocation List containing an invalid value should not result in a usable config
- (void)testInitWithCertificateRevocationListInvalidContent {
    NSDictionary *jsonDict = @{
        @"crl": @[@"not-a-key-hash"]
    };
    NSError *jsonError = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&jsonError];

    XCTAssertNotNil(jsonError);
    XCTAssertNil(config);
}

// A Config with blacklisted RevokedCertKeys key should not result in a usable config
- (void)testInitWithBlacklistedRevokedCertKeys {
    NSDictionary *jsonDict = @{
        MMERevokedCertKeys: @[@"not-a-key-hash"]
    };
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&error];

    XCTAssertNil(config);
    XCTAssertNotNil(error);
}

- (void)testInitFromConfigServiceData {
    NSDictionary *jsonDict = @{
        MMEConfigCRLKey: @[],
        MMEConfigTTOKey: @2,
        MMEConfigGFOKey: @500,
        MMEConfigBSOKey: @10,
        MMEConfigTagKey: @"TAG"
    };

    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(config);
    XCTAssertEqualObjects(config.geofenceOverride, @500);
    XCTAssertEqual(config.certificateRevocationList.count, 0);
    XCTAssertEqualObjects(config.telemetryTypeOverride, @2);
    XCTAssertEqualObjects(config.geofenceOverride, @500);
    XCTAssertEqualObjects(config.backgroundStartupOverride, @10);
    XCTAssertEqualObjects(config.eventTag, @"TAG");

    // TODO: These interpretations need to be able to be verified?
    // XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
}

- (void)testInitWithNilGeofenceOverrideIfOutOfRange {
    NSDictionary *dictionary = @{
        MMEConfigTTOKey: @1,
        MMEConfigGFOKey: @90000, //over 9,000
    };
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:dictionary error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(config);
    XCTAssertNil(config.geofenceOverride);
    XCTAssertEqualObjects(config.telemetryTypeOverride, @1);

    // TODO: - Verify in Config update that we are defauling to 300 if out of range
}

-(void)testInitWithAllWrong {
    NSDictionary *dictionary = @{
        @"tto": @"two",
        @"bso": @"ten",
        @"gfo": @"one hundred",
        @"tag": @[@"not",@"two"]
    };

    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:dictionary error:&error];
    XCTAssertNotNil(error);
    XCTAssertNil(config);
}

-(void)testInitWithNullTag {
    NSDictionary *dictionary = @{
        @"tag": NSNull.null
    };
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:dictionary error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(config);
}

@end
