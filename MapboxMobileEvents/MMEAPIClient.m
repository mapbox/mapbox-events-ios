#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEEvent.h"
#import "NSData+MMEGZIP.h"

@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;
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
        
        [self setBaseURL:nil];
        [self setupUserAgent];
    }
    return self;
}

- (void)reconfigure:(MMEEventsConfiguration *)configuration {
    [self.sessionWrapper reconfigure:configuration];
}

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSURLRequest *request = [self requestForEvents:events];
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSError *statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
        if (completionHandler) {
            error = error ?: statusError;
            completionHandler(error);
        }
    }];
}

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self postEvents:@[event] completionHandler:completionHandler];
}

- (void)getConfigurationWithCompletionHandler:(nullable void (^)(NSError * _Nullable error, NSData * _Nullable data))completionHandler {
    NSURLRequest *request = [self requestForConfiguration];
    
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSError *statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
            if (completionHandler) {
                error = error ?: statusError;
                completionHandler(error, data);
            }
        }
    }];
}

- (void)setBaseURL:(NSURL *)baseURL {
    if (baseURL && [baseURL.scheme isEqualToString:@"https"]) {
        _baseURL = baseURL;
    } else {
        _baseURL = [NSURL URLWithString:MMEAPIClientBaseURL];
    }
}

#pragma mark - Utilities

- (NSError *)statusErrorFromRequest:(NSURLRequest *)request andHTTPResponse:(NSHTTPURLResponse *)httpResponse {
    NSError *statusError = nil;
    if (httpResponse.statusCode >= 400) {
        NSString *descriptionFormat = @"The session data task failed. Original request was: %@";
        NSString *reasonFormat = @"The status code was %ld";
        NSString *description = [NSString stringWithFormat:descriptionFormat, request];
        NSString *reason = [NSString stringWithFormat:reasonFormat, (long)httpResponse.statusCode];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description,
                                   NSLocalizedFailureReasonErrorKey: reason};
        statusError = [NSError errorWithDomain:MMEErrorDomain code:1 userInfo:userInfo];
    }
    return statusError;
}

- (NSURLRequest *)requestForConfiguration {
    
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsConfigPath, [self accessToken]];
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:MMEAPIClientBaseAPIURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:self.userAgent forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:MMEAPIClientHeaderFieldContentTypeValue forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodGet];
    
    return [request copy];
}

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
    if (events.count >= 2) {
        NSData *compressedData = [jsonData mme_gzippedData];
        [request setValue:@"gzip" forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
        [request setHTTPBody:compressedData];
    } else {
        [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
        [request setHTTPBody:jsonData];
    }
    
    return [request copy];
}

- (void)setupUserAgent {
    if ([self.applicationBundle objectForInfoDictionaryKey:@"MMEMapboxUserAgentBase"]) {
        self.userAgentBase = [self.applicationBundle objectForInfoDictionaryKey:@"MMEMapboxUserAgentBase"];
    }
    if ([self.applicationBundle objectForInfoDictionaryKey:@"MMEMapboxHostSDKVersion"]) {
        self.hostSDKVersion = [self.applicationBundle objectForInfoDictionaryKey:@"MMEMapboxHostSDKVersion"];
    }
    
    NSString *appName = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appVersion = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumber = [self.applicationBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    self.userAgent = [NSString stringWithFormat:@"%@/%@/%@ %@/%@", appName, appVersion, appBuildNumber, self.userAgentBase, self.hostSDKVersion];
}

@end
