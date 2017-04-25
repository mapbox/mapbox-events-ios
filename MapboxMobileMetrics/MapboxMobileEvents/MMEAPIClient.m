#import "MMEAPIClient.h"
#import "MMEConstants.h"

@interface MMEAPIClient ()

@property (nonatomic, copy) NSURLSession *session;
@property (nonatomic, copy) NSData *digicertCert;
@property (nonatomic, copy) NSData *geoTrustCert;
@property (nonatomic, copy) NSData *testServerCert;
@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic) BOOL usesTestServer;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic) NSBundle *sdkBundle;
@property (nonatomic, copy) NSString *userAgent;

@end

@implementation MMEAPIClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _applicationBundle = [NSBundle mainBundle];
        _sdkBundle = [NSBundle bundleForClass:[self class]];

        [self loadCertficates];
        [self setupBaseURL];
        [self setupUserAgent];
    }
    return self;
}

- (void)postEvents:(NS_ARRAY_OF(MMEEvent *) *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {

}

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {

}

#pragma mark - Utilities

- (void)loadCertficates {
    NSData *certificate;
    [self loadCertificateData:&certificate withName:@"api_mapbox_com-digicert"];
    self.digicertCert = certificate;
    [self loadCertificateData:&certificate withName:@"api_mapbox_com-geotrust"];
    self.geoTrustCert = certificate;
    [self loadCertificateData:&certificate withName:@"api_mapbox_staging"];
    self.testServerCert = certificate;
}

- (void)loadCertificateData:(NSData **)certificateData withName:(NSString *)name {
    NSString *certPath = [self.sdkBundle pathForResource:name ofType:@"der" inDirectory:nil];
    *certificateData = [NSData dataWithContentsOfFile:certPath];
}

- (void)setupBaseURL {
    NSString *testServerURLString = [[NSUserDefaults standardUserDefaults] stringForKey:MMETelemetryTestServerURL];
    NSURL *testServerURL = [NSURL URLWithString:testServerURLString];
    if (testServerURL && [testServerURL.scheme isEqualToString:@"https"]) {
        self.baseURL = testServerURL;
        self.usesTestServer = YES;
    } else {
        self.baseURL = [NSURL URLWithString:MMEAPIClientBaseURL];
    }
}

- (void)setupUserAgent {
    NSString *appName = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appVersion = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumber = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *shortVersion = [self.sdkBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.userAgent = [NSString stringWithFormat:@"%@/%@/%@ %@/%@", appName, appVersion, appBuildNumber, MMEAPIClientUserAgentBase, shortVersion];
}

@end
