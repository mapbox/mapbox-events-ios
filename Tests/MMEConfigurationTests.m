#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConfig.h"
#import "MMEConfigation.h"
#import "MMEBundleInfoFake.h"
#import "MMELogger.h"
#import "MMEConstants.h"
#import "MMEDate.h"

@interface MMEConfigation (Tests)

/// Unique Identifier for the client
-(void)setClientId:(NSString *)clientId;
-(void)setEventFlushCount:(NSUInteger)eventFlushCount;
-(void)setEventFlushInterval:(NSTimeInterval)eventFlushInterval;
- (void)setIdentifierRotationInterval:(NSTimeInterval)identifierRotationInterval;
- (void)setConfigUpdateInterval:(NSTimeInterval)configUpdateInterval;
- (void)reset;
- (void)updateFromAccountType:(NSInteger)typeCode;
@end

@interface MMEConfigurationTests : XCTestCase
@property (nonatomic, strong) MMEConfigation* configuration;
@end

@implementation MMEConfigurationTests

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
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];
    [self.configuration reset];
}

// MARK: - Defaults

- (void)testResetConfiguration {
    XCTAssertGreaterThan(self.configuration.userDefaults.volatileDomainNames.count, 0);
}

- (void)testEventFlushCountDefault {
    XCTAssertEqual(self.configuration.eventFlushCount, 180);
}

- (void)testEventFlushIntervalDefault {
    XCTAssertEqual(self.configuration.eventFlushInterval, 180);
}

- (void)testEventIdentifierRotationDefault {
    XCTAssertEqual(self.configuration.identifierRotationInterval, 86400);
}

- (void)testEventConfigurationUpdateIntervalDefault {
    XCTAssertEqual(self.configuration.configUpdateInterval, 86400);
}

- (void)testEventBackgroundStartupDelayDefault {
    XCTAssertEqual(self.configuration.backgroundStartupDelay, 15);
}

- (void)testUserAgentGenerationDefault {
    NSLog(@"User-Agent: %@", self.configuration.userAgentString);
    XCTAssertNotNil(self.configuration.userAgentString);
}

// MARK: - Location Collection

- (void)testEventIsCollectionEnabledDefault {
    XCTAssertTrue(self.configuration.isCollectionEnabled);
}

- (void)testEventIsCollectionEnabledInSimulatorDefault {
    XCTAssertTrue(self.configuration.isCollectionEnabledInSimulator);
}

// MARK: - Defaults Loaded from Bundle

- (void)testCustomProfileOverMaxValues {

    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @9001,
        MMECustomGeofenceRadius: @9001
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.configuration.backgroundGeofence, 300);
    XCTAssertEqual(self.configuration.startupDelay, 1);
}

- (void)testCustomProfileUnderMinValues {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @-42,
        MMECustomGeofenceRadius: @10
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.configuration.backgroundGeofence, 300);
    XCTAssertEqual(self.configuration.startupDelay, 1);
}

- (void)testCustomProfile {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @2,
        MMECustomGeofenceRadius: @300
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.configuration.backgroundGeofence, 300);
    XCTAssertEqual(self.configuration.startupDelay, 2);
}

- (void)testCustomProfileInvalidValues {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @"unicorn",
        MMECustomGeofenceRadius: @"fence"
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertEqual(self.configuration.backgroundGeofence, 300);
    XCTAssertEqual(self.configuration.startupDelay, 1);
}

- (void)testDebugLoggingEnabledFromBundle {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEDebugLogging: @YES
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];
    XCTAssertTrue([MMELogger.sharedLogger isEnabled]);
}

- (void)testDefaultsFromFomBundle {
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEAccountType: @1,
        @"MMEMapboxUserAgentBase" : @"com.mapbox.test",
        @"MMEMapboxHostSDKVersion": @"1.0.0"
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];

    XCTAssertFalse(self.configuration.isCollectionEnabled);
    XCTAssertEqualObjects(self.configuration.legacyUserAgentBase, @"com.mapbox.test");
    XCTAssertEqualObjects(self.configuration.legacyHostSDKVersion, @"1.0.0");
}

- (void)testAccountUpdate {
    self.configuration.isCollectionEnabled = YES;
    self.configuration.isCollectionEnabledInBackground = YES;
    [self.configuration updateFromAccountType:MMEAccountType1];
    XCTAssertEqual(self.configuration.isCollectionEnabled, NO);

    self.configuration.isCollectionEnabled = YES;
    self.configuration.isCollectionEnabledInBackground = YES;

    [self.configuration updateFromAccountType:MMEAccountType2];
    XCTAssertEqual(self.configuration.isCollectionEnabledInBackground, NO);

    self.configuration.isCollectionEnabled = YES;
    self.configuration.isCollectionEnabledInBackground = YES;
    [self.configuration updateFromAccountType:0];
    XCTAssertEqual(self.configuration.isCollectionEnabled, YES);
    XCTAssertEqual(self.configuration.isCollectionEnabledInBackground, YES);
}

// MARK: - Background Collection

- (void)testEventIsCollectionEnabledInBackgroundDefault {
    XCTAssertTrue(self.configuration.isCollectionEnabledInBackground);
}

- (void)testStartupDelayDefault {
    XCTAssertEqual(self.configuration.startupDelay, 1);
}

- (void)testEventBackgroundGeofenceDefault {
    XCTAssertEqual(self.configuration.backgroundGeofence, 300);
}

// MARK: - Certificate Revocation List

- (void)testCertificateRevocationList {
    XCTAssertEqual(self.configuration.certificateRevocationList.count, 2);
}

// MARK: - Setters and Getters

- (void)testSetAccessToken {
    self.configuration.accessToken = nil;
    XCTAssertNil(self.configuration.accessToken);

    self.configuration.accessToken = @"pk.12345";;
    XCTAssertEqualObjects(self.configuration.accessToken, @"pk.12345");
}

- (void)testSetLegacyUserAgentBase {
    self.configuration.legacyUserAgentBase = @"foo";
    XCTAssertEqualObjects(self.configuration.legacyUserAgentBase, @"foo");
}

- (void)testSetLegacyHostSDKVersion {
    self.configuration.legacyHostSDKVersion = @"bar";
    XCTAssertEqualObjects(self.configuration.legacyHostSDKVersion, @"bar");
}

- (void)testChinaRegionSetter {
    self.configuration.isChinaRegion = YES;
    XCTAssertTrue(self.configuration.isChinaRegion);

    self.configuration.isChinaRegion = NO;
    XCTAssertFalse(self.configuration.isChinaRegion);

    self.configuration.isChinaRegion = YES;
    XCTAssertTrue(self.configuration.isChinaRegion);
}

- (void)testIsCollectionSetter {
    self.configuration.isCollectionEnabled = NO;
    XCTAssertEqual(self.configuration.isCollectionEnabled, NO);

    self.configuration.isCollectionEnabled = YES;
    XCTAssertEqual(self.configuration.isCollectionEnabled, YES);
}

- (void)testIsCollectionEnabledInBackgroundSetter {
    self.configuration.isCollectionEnabledInBackground = NO;
    XCTAssertEqual(self.configuration.isCollectionEnabledInBackground, NO);

    self.configuration.isCollectionEnabledInBackground = YES;
    XCTAssertEqual(self.configuration.isCollectionEnabledInBackground, YES);
}

- (void)testClientId {
    // Client ID should be non-nil
    XCTAssertNotNil(self.configuration.clientId);

    // Client ID should be the same on mutple accesses
    XCTAssertEqualObjects(self.configuration.clientId, self.configuration.clientId);
}

- (void)testSetClientId {

    // Client ID should be able to be set and retreived
    self.configuration.clientId = @"foo";
    XCTAssertEqualObjects(@"foo", self.configuration.clientId);
}

- (void)testSetEventFlushCount {
    self.configuration.eventFlushCount = 4;
    XCTAssertEqual(self.configuration.eventFlushCount, 4);
}

- (void)testSetEventFlushInterval {
    self.configuration.eventFlushInterval = 10;
    XCTAssertEqual(self.configuration.eventFlushInterval, 10);
}

- (void)testSetEventIdentifierRotation {
    self.configuration.identifierRotationInterval = 37;
    XCTAssertEqual(self.configuration.identifierRotationInterval, 37);
}

- (void)testSetConfigUpdateInterval {

    self.configuration.configUpdateInterval = 13;
    XCTAssertEqual(self.configuration.configUpdateInterval, 13);
}



// MARK: - Service Configuration Update Date

-(void)testConfigUpdates {
    MMEDate* date = [MMEDate dateWithDate:[NSDate dateWithTimeIntervalSince1970:0]];
    self.configuration.configUpdateDate = date;
    XCTAssertNotNil(self.configuration.configUpdateDate);
    XCTAssertEqualObjects(self.configuration.configUpdateDate, date);
}

// MARK: - Service URLs (Defaults)

- (void)testEventsServiceURLDefault {
    XCTAssertEqualObjects(self.configuration.eventsServiceURL.absoluteString, @"https://events.mapbox.com");
}

- (void)testAPIServiceURLDefault {
    XCTAssertEqualObjects(self.configuration.apiServiceURL.absoluteString, @"https://api.mapbox.com");
}

- (void)testConfigServiceURLDefault {
    XCTAssertEqualObjects(self.configuration.configServiceURL.absoluteString, @"https://config.mapbox.com");
}

// MARK: - Service URLs (Overrides)

- (void)testEventsServiceURLOverrideWithString {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = @"https://test.com";
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.configuration.eventsServiceURL.absoluteString, @"https://test.com");
}

- (void)testAPIServiceURLWithString {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = @"https://test.com";
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.configuration.apiServiceURL.absoluteString, @"https://test.com");
}

- (void)testEventsServiceURLOverrideWithURL {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = [NSURL URLWithString:@"https://test.com"];
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.configuration.eventsServiceURL.absoluteString, @"https://test.com");
}

- (void)testAPIServiceURLWithURL {
    NSMutableDictionary* dictionary = [self bundleDefaults];
    dictionary[MMEEventsServiceURL] = [NSURL URLWithString:@"https://test.com"];
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqualObjects(self.configuration.apiServiceURL.absoluteString, @"https://test.com");
}

- (void)testStartupDelayChange {
    NSMutableDictionary* dictionary = [self bundleDefaults];

    // Bundle Loading Requires Custom Profile Key/Value
    dictionary[MMEEventsProfile] = MMECustomProfile;
    dictionary[MMEStartupDelay] = @42;
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqual(self.configuration.startupDelay, 42);
}

- (void)testStartupDelayChangeIgnored {
    NSMutableDictionary* dictionary = [self bundleDefaults];

    // Bundle Loading Requires Custom Profile Key/Value
    // Given value isn't set, expect this value to be ignored and use default
    dictionary[MMEStartupDelay] = @42;
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:dictionary];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle dataStore:NSUserDefaults.mme_configuration];
    XCTAssertEqual(self.configuration.startupDelay, 1);
}

- (void)testChinaRegionSetFromPlist {
    // set the region to CN in the plist
    NSBundle* bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEGLMapboxAPIBaseURL: MMEAPIClientBaseChinaAPIURL
    }];
    self.configuration = [[MMEConfigation alloc] initWithBundle:bundle
                                                    dataStore:NSUserDefaults.mme_configuration];
    XCTAssertTrue(self.configuration.isChinaRegion);
}

- (void)testRestOfWorldRegionURLS {
    self.configuration.isChinaRegion = NO;
    XCTAssertEqualObjects(self.configuration.apiServiceURL.absoluteString, @"https://api.mapbox.com");
    XCTAssertEqualObjects(self.configuration.eventsServiceURL.absoluteString, @"https://events.mapbox.com");
    XCTAssertEqualObjects(self.configuration.configServiceURL.absoluteString, @"https://config.mapbox.com");
}

- (void)testChinaRegionURLS {
    self.configuration.isChinaRegion = YES;
    XCTAssertEqualObjects(self.configuration.apiServiceURL.absoluteString, @"https://api.mapbox.cn");
    XCTAssertEqualObjects(self.configuration.eventsServiceURL.absoluteString, @"https://events.mapbox.cn");
    XCTAssertEqualObjects(self.configuration.configServiceURL.absoluteString, @"https://config.mapbox.cn");
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

    [self.configuration updateWithConfig:config];
    XCTAssertEqual(self.configuration.certificateRevocationList.count, 0);
    XCTAssertEqual(self.configuration.backgroundGeofence, 500);
    XCTAssertEqual(self.configuration.backgroundStartupDelay, 10);
    XCTAssertEqualObjects(self.configuration.eventTag, @"TAG");
}

// MARK: - Certificate Pinning Models

- (void)testExpectedCNHashCount {
    NSArray* chinaHashes = self.configuration.chinaPublicKeys;
    XCTAssertEqual(chinaHashes.count, 54);
}

-(void)testExpectedCOMHashCount {
    NSArray* commercialHashes = self.configuration.comPublicKeys;
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
    MMEConfigation* configuration = [[MMEConfigation alloc] init];
    [configuration updateWithConfig:config];
    NSArray *hashes = configuration.certificatePinningConfig[@"events.mapbox.cn"];
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
    MMEConfigation* configuration = [[MMEConfigation alloc] init];
    [configuration updateWithConfig:config];

    NSArray *hashes = self.configuration.certificatePinningConfig[@"events.mapbox.com"];
    XCTAssertEqual(hashes.count, 53);
}

-(void)testValidateChinaHashes {
    NSArray *cnHashes = self.configuration.certificatePinningConfig[@"events.mapbox.cn"];
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
    NSArray *comHashes = self.configuration.certificatePinningConfig[@"events.mapbox.com"];
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
