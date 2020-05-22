#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConfig.h"
#import "MMEPreferences.h"
#import "MMEBundleInfoFake.h"
#import "MMELogger.h"
#import "MMEConstants.h"
#import "MMEDate.h"

@interface MMEPreferences (Tests)
- (void)reset;
- (void)updateFromAccountType:(NSInteger)typeCode;
@end

@interface MMEPreferencesTests : XCTestCase
@property (nonatomic, strong) MMEPreferences* preferences;
@end

@implementation MMEPreferencesTests

// Info.Plist Mock
- (NSMutableDictionary*)bundleDefaults {
    // alternate defaults
    return [@{
        MMEStartupDelay: @(MMEStartupDelayDefault), // seconds
        MMEBackgroundGeofence: @(MMEBackgroundGeofenceDefault), // meters
        MMEEventFlushCount: @(MMEEventFlushCountDefault), // events
        MMEEventFlushInterval: @(MMEEventFlushIntervalDefault), // seconds
        MMEIdentifierRotationInterval: @(MMEIdentifierRotationIntervalDefault), // 24 hours
        MMEConfigurationUpdateInterval: @(MMEConfigurationUpdateIntervalDefault), // 24 hours
        MMEBackgroundStartupDelay: @(MMEBackgroundStartupDelayDefault), // seconds
        MMECollectionDisabled: @NO,
        MMECollectionEnabledInSimulator: @YES,
        MMECollectionDisabledInBackground: @YES,
        MMEConfigEventTag: @"tag",
        MMECertificateRevocationList:@[
                @"T4XyKSRwZ5icOqGmJUXiDYGa+SaXKTGQXZwhqpwNTEo=",
                @"KlV7emqpeM6V2MtDEzSDzcIob6VwkdWHiVsNQQzTIeo="]
    } mutableCopy];

}

- (void)setUp {
    [super setUp];

    // Default Setup
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:[self bundleDefaults]];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];
    [self.preferences reset];
}

// MARK: - Defaults

- (void)testResetConfiguration {
    XCTAssertGreaterThan(self.preferences.userDefaults.volatileDomainNames.count, 0);
}

- (void)testEventFlushCountDefault {
    XCTAssertEqual(self.preferences.eventFlushCount, 180);
}

- (void)testEventFlushIntervalDefault {
    XCTAssertEqual(self.preferences.eventFlushInterval, 180);
}

- (void)testEventIdentifierRotationDefault {
    XCTAssertEqual(self.preferences.identifierRotationInterval, 86400);
}

- (void)testEventConfigurationUpdateIntervalDefault {
    XCTAssertEqual(self.preferences.configUpdateInterval, 86400);
}

- (void)testEventBackgroundStartupDelayDefault {
    XCTAssertEqual(self.preferences.backgroundStartupDelay, 15);
}

- (void)testUserAgentGenerationDefault {
    NSLog(@"User-Agent: %@", self.preferences.userAgentString);
    XCTAssertNotNil(self.preferences.userAgentString);
}

// MARK: - Location Collection

- (void)testEventIsCollectionEnabledDefault {
    XCTAssertTrue(self.preferences.isCollectionEnabled);
}

- (void)testEventIsCollectionEnabledInSimulatorDefault {
    XCTAssertTrue(self.preferences.isCollectionEnabledInSimulator);
}

// MARK: - Defaults Loaded from Bundle

- (void)testCustomProfileOverMaxValues {

    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @9001,
        MMECustomGeofenceRadius: @9001
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.preferences.backgroundGeofence, 300);
    XCTAssertEqual(self.preferences.startupDelay, 1);
}

- (void)testCustomProfileUnderMinValues {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @-42,
        MMECustomGeofenceRadius: @10
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.preferences.backgroundGeofence, 300);
    XCTAssertEqual(self.preferences.startupDelay, 1);
}

- (void)testCustomProfile {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @2,
        MMECustomGeofenceRadius: @300
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.preferences.backgroundGeofence, 300);
    XCTAssertEqual(self.preferences.startupDelay, 2);
}

- (void)testCustomProfileInvalidValues {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @"unicorn",
        MMECustomGeofenceRadius: @"fence"
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.preferences.backgroundGeofence, 300);
    XCTAssertEqual(self.preferences.startupDelay, 1);
}

- (void)testDebugLoggingEnabledFromBundle {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEDebugLogging: @YES
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];
    XCTAssertTrue([MMELogger.sharedLogger isEnabled]);
}

- (void)testDefaultsFromFomBundle {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEAccountType: @1,
        @"MMEMapboxUserAgentBase" : @"com.mapbox.test",
        @"MMEMapboxHostSDKVersion": @"1.0.0"
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertFalse(self.preferences.isCollectionEnabled);
    XCTAssertEqualObjects(self.preferences.legacyUserAgentBase, @"com.mapbox.test");
    XCTAssertEqualObjects(self.preferences.legacyHostSDKVersion, @"1.0.0");
}

- (void)testPersistentObjectSetDelete {
    [NSUserDefaults.mme_configuration mme_setObject:@2 forPersistentKey:MMEAccountType];
    XCTAssert([[NSUserDefaults.mme_configuration objectForKey:MMEAccountType] intValue] == 2);

    [NSUserDefaults.mme_configuration mme_deleteObjectForPersistentKey:MMEAccountType];
    XCTAssertNil([NSUserDefaults.mme_configuration objectForKey:MMEAccountType]);
}

- (void)testAccountUpdate {
    self.preferences.isCollectionEnabled = YES;
    self.preferences.isCollectionEnabledInBackground = YES;
    [self.preferences updateFromAccountType:MMEAccountType1];
    XCTAssertEqual(self.preferences.isCollectionEnabled, NO);

    self.preferences.isCollectionEnabled = YES;
    self.preferences.isCollectionEnabledInBackground = YES;

    [self.preferences updateFromAccountType:MMEAccountType2];
    XCTAssertEqual(self.preferences.isCollectionEnabledInBackground, NO);

    self.preferences.isCollectionEnabled = YES;
    self.preferences.isCollectionEnabledInBackground = YES;
    [self.preferences updateFromAccountType:0];
    XCTAssertEqual(self.preferences.isCollectionEnabled, YES);
    XCTAssertEqual(self.preferences.isCollectionEnabledInBackground, YES);
}

// MARK: - Background Collection

- (void)testEventIsCollectionEnabledInBackgroundDefault {
    XCTAssertFalse(self.preferences.isCollectionEnabledInBackground);
}

- (void)testStartupDelayDefault {
    XCTAssertEqual(self.preferences.startupDelay, 1);
}

- (void)testEventBackgroundGeofenceDefault {
    XCTAssertEqual(self.preferences.backgroundGeofence, 300);
}

// MARK: - Certificate Revocation List

- (void)testCertificateRevocationList {
    XCTAssertEqual(self.preferences.certificateRevocationList.count, 2);
}

// MARK: - Setters and Getters

- (void)testSetAccessToken {
    self.preferences.accessToken = nil;
    XCTAssertNil(self.preferences.accessToken);

    self.preferences.accessToken = @"pk.12345";;
    XCTAssertEqualObjects(self.preferences.accessToken, @"pk.12345");
}

- (void)testSetLegacyUserAgentBase {
    self.preferences.legacyUserAgentBase = @"foo";
    XCTAssertEqualObjects(self.preferences.legacyUserAgentBase, @"foo");
}

- (void)testSetLegacyHostSDKVersion {
    self.preferences.legacyHostSDKVersion = @"bar";
    XCTAssertEqualObjects(self.preferences.legacyHostSDKVersion, @"bar");
}

- (void)testChinaRegionSetter {
    self.preferences.isChinaRegion = YES;
    XCTAssertTrue(self.preferences.isChinaRegion);

    self.preferences.isChinaRegion = NO;
    XCTAssertFalse(self.preferences.isChinaRegion);

    self.preferences.isChinaRegion = YES;
    XCTAssertTrue(self.preferences.isChinaRegion);
}

- (void)testIsCollectionSetter {
    self.preferences.isCollectionEnabled = NO;
    XCTAssertEqual(self.preferences.isCollectionEnabled, NO);

    self.preferences.isCollectionEnabled = YES;
    XCTAssertEqual(self.preferences.isCollectionEnabled, YES);
}

- (void)testIsCollectionEnabledInBackgroundSetter {
    self.preferences.isCollectionEnabledInBackground = NO;
    XCTAssertEqual(self.preferences.isCollectionEnabledInBackground, NO);

    self.preferences.isCollectionEnabledInBackground = YES;
    XCTAssertEqual(self.preferences.isCollectionEnabledInBackground, YES);
}

// MARK: - Service Configuration Update Date

-(void)testConfigUpdates {
    MMEDate* date = [MMEDate dateWithDate:[NSDate dateWithTimeIntervalSince1970:0]];
    self.preferences.configUpdateDate = date;
    XCTAssertNotNil(self.preferences.configUpdateDate);
    XCTAssertEqualObjects(self.preferences.configUpdateDate, date);
}

// MARK: - Service URLs (Defaults)

- (void)testEventsServiceURLDefault {
    XCTAssertEqualObjects(self.preferences.eventsServiceURL.absoluteString, @"https://events.mapbox.com");
}

- (void)testAPIServiceURLDefault {
    XCTAssertEqualObjects(self.preferences.apiServiceURL.absoluteString, @"https://api.mapbox.com");
}

- (void)testConfigServiceURLDefault {
    XCTAssertEqualObjects(self.preferences.configServiceURL.absoluteString, @"https://config.mapbox.com");
}

// MARK: - Service URLs (Overrides)

- (void)testEventsServiceURLOverrideWithString {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = @"https://test.com";
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.preferences.eventsServiceURL.absoluteString, @"https://test.com");
}

- (void)testAPIServiceURLWithString {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = @"https://test.com";
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.preferences.apiServiceURL.absoluteString, @"https://test.com");
}

- (void)testEventsServiceURLOverrideWithURL {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = [NSURL URLWithString:@"https://test.com"];
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.preferences.eventsServiceURL.absoluteString, @"https://test.com");
}

- (void)testAPIServiceURLWithURL {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = [NSURL URLWithString:@"https://test.com"];
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.preferences.apiServiceURL.absoluteString, @"https://test.com");
}

- (void)testStartupDelayChange {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEStartupDelay] = @42;
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqual(self.preferences.startupDelay, 42);
}

- (void)testChinaRegionSetFromPlist {
    // set the region to CN in the plist
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEGLMapboxAPIBaseURL: MMEAPIClientBaseChinaAPIURL
    }];
    self.preferences = [[MMEPreferences alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];
    XCTAssertTrue(self.preferences.isChinaRegion);
}

- (void)testRestOfWorldRegionURLS {
    self.preferences.isChinaRegion = NO;
    XCTAssertEqualObjects(self.preferences.apiServiceURL.absoluteString, @"https://api.mapbox.com");
    XCTAssertEqualObjects(self.preferences.eventsServiceURL.absoluteString, @"https://events.mapbox.com");
    XCTAssertEqualObjects(self.preferences.configServiceURL.absoluteString, @"https://config.mapbox.com");
}

- (void)testChinaRegionURLS {
    self.preferences.isChinaRegion = YES;
    XCTAssertEqualObjects(self.preferences.apiServiceURL.absoluteString, @"https://api.mapbox.cn");
    XCTAssertEqualObjects(self.preferences.eventsServiceURL.absoluteString, @"https://events.mapbox.cn");
    XCTAssertEqualObjects(self.preferences.configServiceURL.absoluteString, @"https://config.mapbox.cn");
}

-(void)testConfigUpdateWithConfig {
    NSDictionary *jsonDict = @{
        MMEConfigCRLKey: @[],
        MMEConfigTTOKey: @2,
        MMEConfigGFOKey: @500,
        MMEConfigBSOKey: @10,
        MMEConfigTagKey: @"TAG"
    };
    NSError *error = nil;
    MMEConfig* config = [[MMEConfig alloc] initWithDictionary:jsonDict error:&error];
    XCTAssertNotNil(config);

    [self.preferences updateWithConfig:config];
    XCTAssertEqual(self.preferences.certificateRevocationList.count, 0);
    XCTAssertEqual(self.preferences.backgroundGeofence, 500);
    XCTAssertEqual(self.preferences.backgroundStartupDelay, 10);
    XCTAssertEqualObjects(self.preferences.eventTag, @"TAG");
}

// MARK: - Certificate Pinning Models

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
    XCTAssertEqual(hashes.count, 53);
}

-(void)testValidateChinaHashes {
    NSArray *cnHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.cn"];
    NSMutableArray *invalidHashes = [[NSMutableArray alloc] init];

    for (NSString *publicKeyHash in cnHashes) {
        NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:publicKeyHash options:(NSDataBase64DecodingOptions)0];
        if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){
            // The subject public key info hash doesn't have a valid size
            [invalidHashes addObject:publicKeyHash];
        }
    }
    XCTAssertEqual(invalidHashes.count, 0);
}

-(void)testValidateCommercialHashes {
    NSArray *comHashes = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[@"events.mapbox.com"];
    NSMutableArray *invalidHashes = [[NSMutableArray alloc] init];

    for (NSString *publicKeyHash in comHashes) {
        NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:publicKeyHash options:(NSDataBase64DecodingOptions)0];
        if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){
            // The subject public key info hash doesn't have a valid size
            [invalidHashes addObject:publicKeyHash];
        }
    }
    XCTAssertEqual(invalidHashes.count, 0);
}

@end
