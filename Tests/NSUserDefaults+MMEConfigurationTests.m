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
        MMEStartupDelay: @(1), // seconds
        MMEBackgroundGeofence: @(300), // meters
        MMEEventFlushCount: @(180), // events
        MMEEventFlushInterval: @(180), // seconds
        MMEIdentifierRotationInterval: @(24 * 60 * 60), // 24 hours
        MMEConfigurationUpdateInterval: @(24 * 60 * 60), // 24 hours
        MMEBackgroundStartupDelay: @(1), // seconds
        MMECertificateRevocationList: @[@"badcert",@"badcert"],
        MMECollectionDisabled: @NO,
        MMECollectionEnabledInSimulator: @YES,
        MMECollectionDisabledInBackground: @YES,
        MMEConfigEventTag: @"tag"
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
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 1);
}

- (void)testUserAgentGenerationDefault {
    NSLog(@"User-Agent: %@", NSUserDefaults.mme_configuration.mme_userAgentString);
    XCTAssert(NSUserDefaults.mme_configuration.mme_userAgentString != nil);
}

- (void)testConfigEventTagDefault {
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventTag isEqual:@"tag"]);
}

// MARK: - Location Collection
- (void)testEventIsCollectionEnabledDefault {
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
}

- (void)testEventIsCollectionEnabledInSimulatorDefault {
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInSimulator);
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

- (void)testUpdateFromConfigServiceData {
    NSDictionary *jsonDict = @{MMEConfigCRLKey: @[@"revoked",@"certs",@"are",@"bad"],
                               MMEConfigTTOKey: @2,
                               MMEConfigGFOKey: @500,
                               MMEConfigBSOKey: @10,
                               MMEConfigTagKey: @"TAG"
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:nil];
    
    [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 500);
    XCTAssert(NSUserDefaults.mme_configuration.mme_certificateRevocationList.count == 4);
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

-(void)testServerSSLPinSet {
    XCTAssert(NSUserDefaults.mme_configuration.mme_serverSSLPinSet.count > 0);
}

- (void)testEventsServiceURLOverride {
    NSMutableDictionary *testInfoPlist = NSBundle.mainBundle.infoDictionary.mutableCopy;
    testInfoPlist[@"MMEEventsServiceURL"]  = @"https://test.com";
    MMEBundleInfoFake *fakeBundle = MMEBundleInfoFake.new;
    fakeBundle.infoDictionaryFake = testInfoPlist;
    [NSBundle mme_setMainBundle:fakeBundle];
    
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventsServiceURL.absoluteString isEqualToString:@"https://test.com"]);
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

@end
