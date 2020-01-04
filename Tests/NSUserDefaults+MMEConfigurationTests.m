#import <XCTest/XCTest.h>

#import "MMEConstants.h"
#import "MMEBundleInfoFake.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEDate.h"

@interface MMENSUserDefaultsTests : XCTestCase
@property (nonatomic) NSMutableDictionary *mutableDomain;

@end

// MARK: -

@implementation MMENSUserDefaultsTests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    NSDictionary *testDefaults = @{ // alternate defaults
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
    };

    [NSBundle mme_setMainBundle:nil];
    [NSUserDefaults mme_resetConfiguration];
    [NSUserDefaults.mme_configuration registerDefaults:testDefaults];
    self.mutableDomain = [testDefaults mutableCopy];
}

- (void)tearDown {
    [NSUserDefaults mme_resetConfiguration];
}

- (void)testResetConfiguration {
    [NSUserDefaults mme_resetConfiguration];
    XCTAssert(NSUserDefaults.mme_configuration.volatileDomainNames.count > 0);
}

- (void)testDefaultsFactoryDefault {
    XCTAssert(NSUserDefaults.mme_configuration != nil);
}

- (void)testVolatileDomainDefault {
    XCTAssert(NSUserDefaults.mme_configuration.volatileDomainNames);
}

- (void)testEventFlushCountDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_eventFlushCount == 180);
}

- (void)testEventFlushIntervalDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_eventFlushInterval == 180);
}

- (void)testEventIdentifierRotationDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_identifierRotationInterval == 86400);
}

- (void)testEventConfigurationUpdateIntervalDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_configUpdateInterval == 86400);
}

- (void)testEventBackgroundStartupDelayDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 15);
}

- (void)testUserAgentGenerationDefault {
    NSLog(@"User-Agent: %@", NSUserDefaults.mme_configuration.mme_userAgentString);
    XCTAssert(NSUserDefaults.mme_configuration.mme_userAgentString != nil);
}

- (void)testConfigEventTagDefault {
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventTag isEqual:@"tag"]);
}

- (void)testCustomProfileOverMaxValues {
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @9001,
        MMECustomGeofenceRadius: @9001
    }];
    [NSUserDefaults.mme_configuration mme_registerDefaults];

    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300);
    XCTAssert(NSUserDefaults.mme_configuration.mme_startupDelay == 1);
}

- (void)testCustomProfileUnderMinValues {
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @-42,
        MMECustomGeofenceRadius: @10
    }];
    [NSUserDefaults.mme_configuration mme_registerDefaults];

    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300);
    XCTAssert(NSUserDefaults.mme_configuration.mme_startupDelay == 1);
}

- (void)testCustomProfile {
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @2,
        MMECustomGeofenceRadius: @420
    }];
    [NSUserDefaults.mme_configuration mme_registerDefaults];

    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 420);
    XCTAssert(NSUserDefaults.mme_configuration.mme_startupDelay == 2);
}

- (void)testCustomProfileInvalidValues {
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEEventsProfile: MMECustomProfile,
        MMEStartupDelay : @"unicorn",
        MMECustomGeofenceRadius: @"fence"
    }];
    [NSUserDefaults.mme_configuration mme_registerDefaults];

    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300);
    XCTAssert(NSUserDefaults.mme_configuration.mme_startupDelay == 1);
}

- (void)testDefaults {
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        MMEAccountType: @1,
        @"MMEMapboxUserAgentBase" : @"com.mapbox.test",
        @"MMEMapboxHostSDKVersion": @"1.0.0"
    }];
    [NSUserDefaults.mme_configuration mme_registerDefaults];

    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
    XCTAssert([NSUserDefaults.mme_configuration.mme_legacyUserAgentBase isEqualToString:@"com.mapbox.test"]);
    XCTAssert([NSUserDefaults.mme_configuration.mme_legacyHostSDKVersion isEqualToString:@"1.0.0"]);
}

- (void)testPersistentObjectSetDelete {
    [NSUserDefaults.mme_configuration mme_setObject:@2 forPersistentKey:MMEAccountType];
    XCTAssert([NSUserDefaults.mme_configuration objectForKey:MMEAccountType] == [NSNumber numberWithInt:2]);
    
    [NSUserDefaults.mme_configuration mme_deleteObjectForPersistentKey:MMEAccountType];
    XCTAssertNil([NSUserDefaults.mme_configuration objectForKey:MMEAccountType]);
}

- (void)testVolatileObjectSetDelete {
    [NSUserDefaults.mme_configuration mme_setObject:@"com.mapbox.map" forVolatileKey:MMELegacyUserAgentBase];
    XCTAssert([(NSString*)[NSUserDefaults.mme_configuration mme_objectForVolatileKey:MMELegacyUserAgentBase] isEqualToString:@"com.mapbox.map"]);
    
    [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMELegacyUserAgentBase];
    XCTAssertNil([NSUserDefaults.mme_configuration objectForKey:MMELegacyUserAgentBase]);
}

// MARK: - Location Collection
- (void)testEventIsCollectionEnabledDefault {
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
}

- (void)testEventIsCollectionEnabledInSimulatorDefault {
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInSimulator);
}

- (void)testEventAccountTypeDefaultsToZero {
    // this is important for Maps functionality related to Events
    XCTAssertTrue([NSUserDefaults.mme_configuration integerForKey:MMEAccountType] == 0);
}

// MARK: - Background Collection

- (void)testEventIsCollectionEnabledInBackgroundDefault {
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
}

- (void)testStartupDelayDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_startupDelay == 1);
}

- (void)testEventBackgroundGeofenceDefault {
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300);
}

// MARK: - Certificate Revocation List

- (void)testCertificateRevocationList {
    XCTAssert(NSUserDefaults.mme_configuration.mme_certificateRevocationList.count == 2);
}

// MARK: - Utilities

- (void)testInvalidCRL {
    NSDictionary *jsonDict = @{MMEConfigCRLKey: @[@"not-a-key-hash"]};
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
    NSError *updateError = [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
    XCTAssertNil(jsonError);
    XCTAssertNotNil(updateError);
}

- (void)testRevokedCertKeys {
    NSDictionary *jsonDict = @{MMERevokedCertKeys: @[@"not-a-key-hash"]};
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
    NSError *updateError = [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
    XCTAssertNil(jsonError);
    XCTAssertNotNil(updateError);
}

- (void)testUpdateFromConfigServiceData {
    NSDictionary *jsonDict = @{MMEConfigCRLKey: @[],
                               MMEConfigTTOKey: @2,
                               MMEConfigGFOKey: @500,
                               MMEConfigBSOKey: @10,
                               MMEConfigTagKey: @"TAG"
    };
    NSError *updateError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&updateError];

    [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
    XCTAssertNil(updateError);
    XCTAssertNotNil(data);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 500);
    XCTAssert(NSUserDefaults.mme_configuration.mme_certificateRevocationList.count == 0);
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 10);
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventTag isEqualToString:@"TAG"]);
}

- (void)testUpdateFromConfigServiceDataAlternatives {
    NSDictionary *jsonDict = @{MMEConfigTTOKey: @1,
                               MMEConfigGFOKey: @90000, //over 9,000
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:nil];
    
    [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300);
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
}

- (void)testSetAccessToken {
    NSUserDefaults.mme_configuration.mme_accessToken = @"pk.12345";
    XCTAssert([NSUserDefaults.mme_configuration.mme_accessToken isEqualToString:@"pk.12345"]);
}

// MARK: - Service Configuration

- (void)testConfigUpdate {
    [NSUserDefaults.mme_configuration mme_setConfigUpdateDate:[MMEDate date]];
    XCTAssertNotNil(NSUserDefaults.mme_configuration.mme_configUpdateDate);
}
    
- (void)testEventsServiceURLDefault {
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventsServiceURL.absoluteString isEqualToString:MMEAPIClientBaseURL]);
}

- (void)testEventsServiceURLOverride {
    NSMutableDictionary *testInfoPlist = NSBundle.mainBundle.infoDictionary.mutableCopy;
    MMEBundleInfoFake *fakeBundle = MMEBundleInfoFake.new;
    
    testInfoPlist[MMEEventsServiceURL]  = @"https://test.com";
    fakeBundle.infoDictionaryFake = testInfoPlist;
    [NSBundle mme_setMainBundle:fakeBundle];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventsServiceURL.absoluteString isEqualToString:@"https://test.com"]);
}

- (void)testEventsServiceURLWithNSURL {
    MMEBundleInfoFake *fakeBundle = MMEBundleInfoFake.new;
    NSMutableDictionary *testInfoPlist = NSBundle.mainBundle.infoDictionary.mutableCopy;
    
    testInfoPlist[MMEEventsServiceURL]  = [NSURL URLWithString:@"https://test.com"];
    fakeBundle.infoDictionaryFake = testInfoPlist;
    [NSBundle mme_setMainBundle:fakeBundle];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventsServiceURL.absoluteString isEqualToString:@"https://test.com"]);
}

- (void)testAPIServiceURLWithNSString {
    MMEBundleInfoFake *fakeBundle = MMEBundleInfoFake.new;
    NSMutableDictionary *testInfoPlist = NSBundle.mainBundle.infoDictionary.mutableCopy;
    
    testInfoPlist[MMEEventsServiceURL]  = @"https://test.com";
    fakeBundle.infoDictionaryFake = testInfoPlist;
    [NSBundle mme_setMainBundle:fakeBundle];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_APIServiceURL.absoluteString isEqualToString:@"https://test.com"]);
}

- (void)testAPIServiceURLWithNSURL {
    MMEBundleInfoFake *fakeBundle = MMEBundleInfoFake.new;
    NSMutableDictionary *testInfoPlist = NSBundle.mainBundle.infoDictionary.mutableCopy;
    
    testInfoPlist[MMEEventsServiceURL]  = [NSURL URLWithString:@"https://test.com"];
    fakeBundle.infoDictionaryFake = testInfoPlist;
    [NSBundle mme_setMainBundle:fakeBundle];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_APIServiceURL.absoluteString isEqualToString:@"https://test.com"]);
}

- (void)testConfigServiceURLWithNSString {
    MMEBundleInfoFake *fakeBundle = MMEBundleInfoFake.new;
    NSMutableDictionary *testInfoPlist = NSBundle.mainBundle.infoDictionary.mutableCopy;
    
    testInfoPlist[MMEConfigServiceURL]  = @"https://test.com";
    fakeBundle.infoDictionaryFake = testInfoPlist;
    [NSBundle mme_setMainBundle:fakeBundle];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_configServiceURL.absoluteString isEqualToString:@"https://test.com"]);
}

- (void)testStartupDelayChange {
    [self.mutableDomain setValue:@42 forKey:MMEStartupDelay];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_startupDelay == 42);
}

- (void)testFlushCountChange {
    [self.mutableDomain setValue:@43 forKey:MMEEventFlushCount];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_eventFlushCount == 43);
}

- (void)testFlushIntervalChange {
    [self.mutableDomain setValue:@44 forKey:MMEEventFlushInterval];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_eventFlushInterval == 44);
}

- (void)testIdentifierRotationIntervalChange {
    [self.mutableDomain setValue:@45 forKey:MMEIdentifierRotationInterval];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_identifierRotationInterval == 45);
}

- (void)testConfigurationUpdateIntervalChange {
    [self.mutableDomain setValue:@46 forKey:MMEConfigurationUpdateInterval];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_configUpdateInterval == 46);
}

- (void)testBackgroundStartupDelayChange {
    [self.mutableDomain setValue:@47 forKey:MMEBackgroundStartupDelay];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 47);
}

- (void)testBackgroundGeofenceChange {
    [self.mutableDomain setValue:@48 forKey:MMEBackgroundGeofence];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 48);
}

- (void)testConfigEventTagChange {
    [self.mutableDomain setValue:@"42" forKey:MMEConfigEventTag];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventTag isEqualToString:@"42"]);
}

- (void)testCertificateRevocationListChange {
    [self.mutableDomain setValue:@[@"Lumberg"] forKey:MMECertificateRevocationList];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssert(NSUserDefaults.mme_configuration.mme_certificateRevocationList.count == 1);
}

- (void)testCollectionEnabledChange {
    [self.mutableDomain setValue:@YES forKey:MMECollectionDisabled];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
}

- (void)testCollectionEnabledInBackgroundChange {
    [self.mutableDomain setValue:@YES forKey:MMECollectionDisabledInBackground];
    [NSUserDefaults.mme_configuration registerDefaults:self.mutableDomain];
    
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
}

- (void)testCNRegionSetFromPlist {
    // set the region to CN in the plist
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:@{MMEGLMapboxAPIBaseURL: MMEAPIClientBaseChinaAPIURL}];
    [NSUserDefaults.mme_configuration mme_registerDefaults];
    
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCNRegion);
}

- (void)testCNRegionSetFromAPI {
    // set the region to CN using the API
    NSUserDefaults.mme_configuration.mme_isCNRegion = YES;
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCNRegion);
}

- (void)testCNRegionToggle {
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCNRegion);
    NSUserDefaults.mme_configuration.mme_isCNRegion = YES;
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCNRegion);
    NSUserDefaults.mme_configuration.mme_isCNRegion = NO;
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCNRegion);
}

- (void)testRoWRegionURLS {
    XCTAssertTrue([NSUserDefaults.mme_configuration.mme_APIServiceURL.absoluteString isEqual:MMEAPIClientBaseAPIURL]);
    XCTAssertTrue([NSUserDefaults.mme_configuration.mme_eventsServiceURL.absoluteString isEqual:MMEAPIClientBaseEventsURL]);
    XCTAssertTrue([NSUserDefaults.mme_configuration.mme_configServiceURL.absoluteString isEqual:MMEAPIClientBaseConfigURL]);
}

- (void)testCNRegionURLS {
    NSUserDefaults.mme_configuration.mme_isCNRegion = YES;
    XCTAssertTrue([NSUserDefaults.mme_configuration.mme_APIServiceURL.absoluteString isEqual:MMEAPIClientBaseChinaAPIURL]);
    XCTAssertTrue([NSUserDefaults.mme_configuration.mme_eventsServiceURL.absoluteString isEqual:MMEAPIClientBaseChinaEventsURL]);
    XCTAssertTrue([NSUserDefaults.mme_configuration.mme_configServiceURL.absoluteString isEqual:MMEAPIClientBaseChinaConfigURL]);
}

- (void)testConfigUpdateDate {
    [NSUserDefaults.mme_configuration mme_setConfigUpdateDate:MMEDate.date];
    [NSUserDefaults.mme_configuration mme_deleteObjectForVolatileKey:MMEConfigUpdateDate];
    
    MMEDate *date = [NSUserDefaults.mme_configuration mme_configUpdateDate];
    
    XCTAssert(date);
}

@end
