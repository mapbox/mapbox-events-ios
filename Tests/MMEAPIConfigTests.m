#import <XCTest/XCTest.h>

#import <MapboxMobileEvents/MMEAPIClient.h>
#import <MapboxMobileEvents/MMEDate.h>
#import <MapboxMobileEvents/MMEEventsManager.h>
#import <MapboxMobileEvents/MMEEventsManager_Private.h>
#import <MapboxMobileEvents/NSUserDefaults+MMEConfiguration.h>
#import <MapboxMobileEvents/NSUserDefaults+MMEConfiguration_Private.h>

#import "MMEServiceFixture.h"
#import "MMEBundleInfoFake.h"

@interface MMEAPIClientConfigTests : XCTestCase <MMEEventsManagerDelegate>
@property(nonatomic) MMEAPIClient<MMEAPIClient> *apiClient;
@property(nonatomic) NSError *eventsError;

@end

// MARK: -

@implementation MMEAPIClientConfigTests

- (void)setUp {
    self.eventsError = nil;

    // reset configuration, set a test access token
    [NSUserDefaults mme_resetConfiguration];

    // inject our config service URL from the MMEService Fixtures
    NSMutableDictionary *fakeInfo = NSBundle.mainBundle.infoDictionary.mutableCopy;
    fakeInfo[MMEConfigServiceURL] = MMEServiceFixture.serviceURL;
    NSBundle.mme_mainBundle = [MMEBundleInfoFake bundleWithFakeInfo:fakeInfo];
    [NSUserDefaults.mme_configuration mme_registerDefaults];

    // be the events manager delegate for the duration
    [MMEEventsManager.sharedManager initializeWithAccessToken:@"test-access-token" userAgentBase:@"user-agent-base-sucks" hostSDKVersion:@"-NaN"];
    MMEEventsManager.sharedManager.delegate = self;
    self.apiClient = (MMEAPIClient<MMEAPIClient> *)MMEEventsManager.sharedManager.apiClient;
}

- (void)tearDown {
    self.apiClient = nil;
}

// MARK: -

- (void) test001_TestHostConfigURL {
    XCTAssert([NSUserDefaults.mme_configuration.mme_configServiceURL isEqual:MMEServiceFixture.serviceURL]);
}

- (void) test002_StaringConfigUdpate {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-null"];
    [self.apiClient startGettingConfigUpdates];

    XCTestExpectation *expectation = nil;
    expectation = [self expectationWithDescription:@"apiClient should be getting config updates"];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        for (int i=0; i<50; i++) {
            if (self.apiClient.isGettingConfigUpdates) {
                [expectation fulfill];
                break;
            } else {
                [NSThread sleepForTimeInterval:0.1];
            }
        }
    });

    [self waitForExpectations:@[expectation] timeout:5];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
}

- (void) test003_StoppingConfigUpdate {
    [self.apiClient stopGettingConfigUpdates];
    XCTAssert(!self.apiClient.isGettingConfigUpdates);
}

- (void) test004_ShortUpdateInterval {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-null"];
    [NSUserDefaults.mme_configuration registerDefaults:@{MMEConfigurationUpdateInterval: @(MME1sTimeout)}];

    XCTAssert(NSUserDefaults.mme_configuration.mme_configUpdateInterval == MME1sTimeout);
    [self.apiClient startGettingConfigUpdates];
    XCTAssert(self.apiClient.isGettingConfigUpdates);
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
}

- (void) test005_1sBSO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-1s-bso"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 1);
}

- (void) test006_10sBSO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-10s-bso"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 10);
}

- (void) test007_100mGFO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-100m-gfo"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300); // default value
}

- (void) test008_1000mGFO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-1000m-gfo"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 1000); // configured value
}

- (void) test009_10000mGFO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-10000m-gfo"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]); // this test runs first, debug timeout
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300); // default value
}

- (void) test010_NullConfig {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-null"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
}

- (void) test010_NullTag {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-null-tag"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssertNil(NSUserDefaults.mme_configuration.mme_eventTag);
}

- (void) test011_NumberTag {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-number-tag"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssertNil(NSUserDefaults.mme_configuration.mme_eventTag);
}

- (void) test012_TestTag {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-test-tag"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
}

- (void) test013_Type1TTO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-type1-tto"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
}

- (void) test014_Type2TTO {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-type2-tto"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssertTrue(NSUserDefaults.mme_configuration.mme_isCollectionEnabled);
    XCTAssertFalse(NSUserDefaults.mme_configuration.mme_isCollectionEnabledInBackground);
}

- (void) test015_All {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-all"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 44);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 444);
    XCTAssert([NSUserDefaults.mme_configuration.mme_eventTag isEqualToString:@"all"]);
}

- (void) test016_AllWrong {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-all-wrong"];
    [self.apiClient startGettingConfigUpdates];

    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
    XCTAssertNil(self.eventsError);
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundStartupDelay == 15); // default
    XCTAssert(NSUserDefaults.mme_configuration.mme_backgroundGeofence == 300); // default
    XCTAssertNil(NSUserDefaults.mme_configuration.mme_eventTag); // default
}

- (void) test017_configShouldNotAcceptFutureDate {
    [NSUserDefaults.mme_configuration mme_setConfigUpdateDate:(MMEDate *)[MMEDate distantFuture]];
    
    XCTAssertNil(NSUserDefaults.mme_configuration.mme_configUpdateDate);
}

- (void) test018_configShouldUpdateOnStartWithPastDate {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    [NSUserDefaults.mme_configuration mme_setConfigUpdateDate:(MMEDate *)[MMEDate distantPast]];
    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-null"];

    [self.apiClient startGettingConfigUpdates];
    XCTAssert(self.apiClient.isGettingConfigUpdates);
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssertNil(configError);
}

- (void) test019_configShouldUpdateClockOffset {
    XCTSkipIf(([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 14, .minorVersion = 0, .patchVersion = 0}]), @"Skip, since CFSocketInvalidate crashes with EXC_GUARD on iOS 14");

    NSError *configError = nil;
    MMEServiceFixture *configFixture = [MMEServiceFixture serviceFixtureWithResource:@"config-long-ago"];
    [self.apiClient startGettingConfigUpdates];
    XCTAssert(self.apiClient.isGettingConfigUpdates);
    XCTAssert([configFixture waitForConnectionWithTimeout:MME10sTimeout error:&configError]);
    XCTAssert(fabs(MMEDate.recordedTimeOffsetFromServer) - fabs(MMEDate.date.timeIntervalSince1970) < MME10sTimeout);
}

// MARK: - MMEEventsManagerDelegate

- (void) eventsManager:(MMEEventsManager *)eventsManager didEncounterError:(NSError *)error {
    NSLog(@"%@ eventsManger:didEncounterError: %@", NSStringFromClass(self.class), error);
    self.eventsError = error;
}

@end
