#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEEvent.h"
#import "NSData+MMEGZIP.h"

@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic) NSBundle *sdkBundle;
@property (nonatomic, copy) NSString *userAgent;

@end

@implementation MMEAPIClient

- (instancetype)initWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion {
    self = [super init];
    if (self) {
        _accessToken = accessToken;
        _userAgentBase = userAgentBase;
        _hostSDKVersion = hostSDKVersion;
        _sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
        _applicationBundle = [NSBundle mainBundle];
        _sdkBundle = [self resolveAndReturnSDKBundle];
        
        [self setupBaseURL];
        [self setupUserAgent];
    }
    return self;
}

- (NSBundle *)resolveAndReturnSDKBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    // If packaged as a static library, look for the resources bundle in the host app's bundle
    if (![bundle.infoDictionary[@"CFBundlePackageType"] isEqualToString:@"FMWK"]) {
        bundle = [NSBundle bundleWithPath:[_applicationBundle pathForResource:@"resources" ofType:@"bundle"]];
    }
    return bundle;
}

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSURLRequest *request = [self requestForEvents:events];
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *statusError = nil;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode >= 400) {
            NSString *descriptionFormat = [self.sdkBundle localizedStringForKey:@"API_CLIENT_400_DESC" value:@"" table:nil];
            NSString *reasonFormat = [self.sdkBundle localizedStringForKey:@"API_CLIENT_400_REASON" value:@"" table:nil];
            NSString *description = [NSString stringWithFormat:descriptionFormat, request];
            NSString *reason = [NSString stringWithFormat:reasonFormat, (long)httpResponse.statusCode];
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description,
                                       NSLocalizedFailureReasonErrorKey: reason};
            statusError = [NSError errorWithDomain:MMEErrorDomain code:1 userInfo:userInfo];
        }
        if (completionHandler) {
            error = error ?: statusError;
            completionHandler(error);
        }
    }];
}

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self postEvents:@[event] completionHandler:completionHandler];
}

- (NSString *)accessToken {
    NSString *stagingAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:MMETelemetryStagingAccessToken];
    if (stagingAccessToken) {
        return stagingAccessToken;
    }
    return _accessToken;
}

#pragma mark - Utilities

- (NSURLRequest *)requestForEvents:(NSArray *)events {

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
    
    // Compressing less than 2 events can have a negative impact on the size.
    if (events.count > 1) {
        NSData *compressedData = [jsonData mme_gzippedData];
        [request setValue:@"gzip" forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
        [request setHTTPBody:compressedData];
    }

    // Set JSON data if events.count were less than 3 or something went wrong with compressing HTTP body data.
    if (!request.HTTPBody) {
        [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
        [request setHTTPBody:jsonData];
    }
    
    return [request copy];
}

- (void)setupBaseURL {
    NSString *testServerURLString = [[NSUserDefaults standardUserDefaults] stringForKey:MMETelemetryTestServerURL];
    NSURL *testServerURL = [NSURL URLWithString:testServerURLString];
    if (testServerURL && [testServerURL.scheme isEqualToString:@"https"]) {
        self.baseURL = testServerURL;
        self.sessionWrapper.usesTestServer = YES;
    } else {
        self.baseURL = [NSURL URLWithString:MMEAPIClientBaseURL];
    }
}

- (void)setupUserAgent {
    NSString *appName = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appVersion = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumber = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    self.userAgent = [NSString stringWithFormat:@"%@/%@/%@ %@/%@", appName, appVersion, appBuildNumber, self.userAgentBase, self.hostSDKVersion];
}

@end
