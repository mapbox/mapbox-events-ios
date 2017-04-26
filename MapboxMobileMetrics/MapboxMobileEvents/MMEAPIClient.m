#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEEvent.h"

@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
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
        _sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
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
    NSURLRequest *request = [self requestForEvents:@[event]];

    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *statusError = nil;
        if (httpResponse.statusCode >= 400) {
            statusError = [NSError errorWithDomain:@"mapbox.com" code:99 userInfo:nil];
        }

        completionHandler(statusError);
    }];
}

#pragma mark - Utilities

- (NSURLRequest *)requestForEvents:(NS_ARRAY_OF(MMEEvent *) *)events {

    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsPath, [self accessToken]];

    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setValue:self.userAgent forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:MMEAPIClientHeaderFieldContentTypeValue forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];

    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];

    //    // Compressing less than 3 events can have a negative impact on the size.
    //    if (events.count > 2) {
    //        NSData *compressedData = [jsonData mgl_compressedData];
    //        [request setValue:@"deflate" forHTTPHeaderField:MGLAPIClientHeaderFieldContentEncodingKey];
    //        [request setHTTPBody:compressedData];
    //    }

    // Set JSON data if events.count were less than 3 or something went wrong with compressing HTTP body data.
    if (!request.HTTPBody) {
        [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
        [request setHTTPBody:jsonData];
    }
    
    return [request copy];
}

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
