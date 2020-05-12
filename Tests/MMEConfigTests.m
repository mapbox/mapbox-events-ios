#import <XCTest/XCTest.h>
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConfig.h"

@interface MMEConfigTests : XCTestCase

@end

@implementation MMEConfigTests

//- (void)testInvalidCRL {
//    NSDictionary *jsonDict = @{
//        @"crl": @[@"not-a-key-hash"]
//    };
//    NSError *jsonError = nil;
//    [MMEConfig alloc] init
//
//    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
//    NSError *updateError = [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
//    XCTAssertNil(jsonError);
//    XCTAssertNotNil(updateError);
//}

// An Certificate Revocation List containing an invalid value should not result in a usable config
- (void)testCertificateRevocationListInvalidContent {
    NSDictionary *jsonDict = @{
        @"crl": @[@"not-a-key-hash"]
    };
    NSError *jsonError = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&jsonError];

    XCTAssertNotNil(jsonError);
    XCTAssertNil(config);
}

// A Config with blacklisted RevokedCertKeys key should not result in a usable config
- (void)testBlacklistedRevokedCertKeys {
    NSDictionary *jsonDict = @{MMERevokedCertKeys: @[@"not-a-key-hash"]};
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&error];

    XCTAssertNil(config);
    XCTAssertNotNil(error);
}

- (void)testUpdateFromConfigServiceData {
    NSDictionary *jsonDict = @{MMEConfigCRLKey: @[],
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

    // TODO: These interpretations need to be able to be verified
    // XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
    // XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 10);
}

- (void)testNilGeofenceOverrideIfOutOfRange {
    NSDictionary *jsonDict = @{MMEConfigTTOKey: @1,
                               MMEConfigGFOKey: @90000, //over 9,000
    };
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(config);
    XCTAssertNil(config.geofenceOverride);
    XCTAssertEqualObjects(config.telemetryTypeOverride, @1);

    // TODO: - Verify in Config update that we are defauling to 300 if out of range
}

@end
