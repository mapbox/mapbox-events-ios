#import <XCTest/XCTest.h>
#import "MMEAPIClient.h"
#import "MMEConstants.h"

@interface MMEAPIClientTests : XCTestCase

@property (nonatomic) MMEAPIClient *apiClient;

@end

@interface MMEAPIClient ()

@property (nonatomic, copy) NSURLSession *session;
@property (nonatomic, copy) NSData *digicertCert;
@property (nonatomic, copy) NSData *geoTrustCert;
@property (nonatomic, copy) NSData *testServerCert;
@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic) BOOL usesTestServer;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic, copy) NSString *userAgent;

- (void)setupUserAgent;

@end

@implementation MMEAPIClientTests

- (void)setUp {
    [super setUp];
    self.apiClient = [[MMEAPIClient alloc] init];
}

- (void)testInitialization {
    XCTAssertNotNil(self.apiClient.session);

    [self loadAndCheckCertificateWithName:@"api_mapbox_com-digicert" comparedToAPIClientCertificate:self.apiClient.digicertCert];
    [self loadAndCheckCertificateWithName:@"api_mapbox_com-geotrust" comparedToAPIClientCertificate:self.apiClient.geoTrustCert];
    [self loadAndCheckCertificateWithName:@"api_mapbox_staging" comparedToAPIClientCertificate:self.apiClient.testServerCert];
}

- (void)testSettingUpBaseURL {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MMETelemetryTestServerURL];
    self.apiClient = [[MMEAPIClient alloc] init];

    XCTAssertEqualObjects([NSURL URLWithString:MMEAPIClientBaseURL], self.apiClient.baseURL);
}

- (void)testSettingBaseURLWithTestServer {
    NSString *testURLString = @"https://test.com";
    [[NSUserDefaults standardUserDefaults] setObject:testURLString forKey:MMETelemetryTestServerURL];
    self.apiClient = [[MMEAPIClient alloc] init];

    XCTAssertTrue(self.apiClient.usesTestServer);
    XCTAssertEqualObjects(self.apiClient.baseURL, [NSURL URLWithString:testURLString]);

    NSString *testURLStringBad = @"http://test.com";
    [[NSUserDefaults standardUserDefaults] setObject:testURLStringBad forKey:MMETelemetryTestServerURL];
    self.apiClient = [[MMEAPIClient alloc] init];

    XCTAssertFalse(self.apiClient.usesTestServer);
    XCTAssertEqualObjects([NSURL URLWithString:MMEAPIClientBaseURL], self.apiClient.baseURL);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MMETelemetryTestServerURL];
}

- (void)testSettingUpUserAgent {
    NSBundle *fakeApplicationBundle = [NSBundle bundleForClass:[MMEAPIClientTests class]];
    NSBundle *sdkBundle = [NSBundle bundleForClass:[MMEAPIClient class]];

    self.apiClient.applicationBundle = fakeApplicationBundle;
    [self.apiClient setupUserAgent];

    NSString *appName = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appVersion = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumber = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *shortVersion = [sdkBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    NSString *expectedUserAgent = [NSString stringWithFormat:@"%@/%@/%@ %@/%@", appName, appVersion, appBuildNumber, MMEAPIClientUserAgentBase, shortVersion];
    XCTAssertEqualObjects(expectedUserAgent, self.apiClient.userAgent);
}

#pragma mark - Utilities

- (void)loadAndCheckCertificateWithName:(NSString *)name comparedToAPIClientCertificate:(NSData *)APIClientCertificate {
    NSBundle *bundle = [NSBundle bundleForClass:[MMEAPIClient class]];
    NSString *certPath = [bundle pathForResource:name ofType:@"der" inDirectory:nil];
    NSData *certificateData = [NSData dataWithContentsOfFile:certPath];
    XCTAssertEqualObjects(certificateData, APIClientCertificate);
}

@end
