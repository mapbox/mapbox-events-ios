#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEEvent.h"
#import "NSData+MMEGZIP.h"
#import "MMEMetricsManager.h"
#import "MMEEventsManager.h"

typedef NS_ENUM(NSInteger, MMEErrorCode) {
    MMESessionFailedError,
    MMEUnexpectedResponseError
};

@import MobileCoreServices;

#pragma mark -

@interface MMEEventsManager (Private)
- (void)pushEvent:(MMEEvent *)event;
@end

#pragma mark -

@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;

@end

int const kMMEMaxRequestCount = 1000;

#pragma mark -

@implementation MMEAPIClient

@synthesize userAgent;

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

- (void) dealloc {
    [self.sessionWrapper invalidate];
}

#pragma mark -

- (void)reconfigure:(MMEEventsConfiguration *)configuration {
    [self.sessionWrapper reconfigure:configuration];
}

- (NSArray *)batchFromEvents:(NSArray *)events {
    NSMutableArray *eventBatches = [[NSMutableArray alloc] init];
    int eventsRemaining = (int)[events count];
    int i = 0;
    
    while (eventsRemaining) {
        NSRange range = NSMakeRange(i, MIN(kMMEMaxRequestCount, eventsRemaining));
        NSArray *batchArray = [events subarrayWithRange:range];
        [eventBatches addObject:batchArray];
        eventsRemaining -= range.length;
        i += range.length;
    }
    
    return eventBatches;
}

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [MMEMetricsManager.sharedManager updateMetricsFromEventQueue:events];
    
    NSArray *eventBatches = [self batchFromEvents:events];
    
    for (NSArray *batch in eventBatches) {
        NSURLRequest *request = [self requestForEvents:batch];
        if (request) {
            [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
                
                NSError *statusError = nil;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
                } else {
                    statusError = [self unexpectedResponseErrorfromRequest:request andResponse:response];
                }
                error = error ?: statusError;
                
                [MMEMetricsManager.sharedManager updateMetricsFromEventCount:events.count request:request error:error];
                
                if (completionHandler) {
                    completionHandler(error);
                }
            }];
        }
        [MMEMetricsManager.sharedManager updateMetricsFromEventCount:events.count request:nil error:nil];
    }

    [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
}

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self postEvents:@[event] completionHandler:completionHandler];
}

- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSData *binaryData = [self createBodyWithBoundary:boundary metadata:metadata filePaths:filePaths];
    NSURLRequest *request = [self requestForBinary:binaryData boundary:boundary];
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
        
        NSError *statusError = nil;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
        if (completionHandler) {
            error = error ?: statusError;
            completionHandler(error);
            
            [MMEMetricsManager.sharedManager updateMetricsFromEventCount:filePaths.count request:request error:error];
        }

        [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
    }];
}

- (void)getConfigurationWithCompletionHandler:(nullable void (^)(NSError * _Nullable error, NSData * _Nullable data))completionHandler {
    NSURLRequest *request = [self requestForConfiguration];
    
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
        
        NSError *statusError = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
        } else {
            statusError = [self unexpectedResponseErrorfromRequest:request andResponse:response];
        }
        if (completionHandler) {
            error = error ?: statusError;
            completionHandler(error, data);
            
            [MMEMetricsManager.sharedManager updateMetricsFromEventCount:0 request:request error:error];
        }
        [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
    }];
}

- (void)setBaseURL:(NSURL *)baseURL {
    if (baseURL && [baseURL.scheme isEqualToString:@"https"]) {
        _baseURL = baseURL;
    } else if ([[_applicationBundle objectForInfoDictionaryKey:@"MGLMapboxAPIBaseURL"] isEqualToString:MMEAPIClientBaseChinaAPIURL]) {
        _baseURL = [NSURL URLWithString:MMEAPIClientBaseChinaEventsURL];
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
        NSString *description = [NSString stringWithFormat:descriptionFormat, request ?: [NSNull null]];
        NSString *reason = [NSString stringWithFormat:reasonFormat, (long)httpResponse.statusCode];
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:reason forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setValue:httpResponse forKey:MMEResponseKey];
        
        statusError = [NSError errorWithDomain:MMEErrorDomain code:MMESessionFailedError userInfo:userInfo];
    }
    return statusError;
}

- (NSError *)unexpectedResponseErrorfromRequest:(nonnull NSURLRequest *)request andResponse:(NSURLResponse *)response {
    NSString *descriptionFormat = @"The session data task failed. Original request was: %@";
    NSString *description = [NSString stringWithFormat:descriptionFormat, request ?: [NSNull null]];
    NSString *reason = @"Unexpected response";
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:reason forKey:NSLocalizedFailureReasonErrorKey];
    [userInfo setValue:response forKey:MMEResponseKey];
    
    NSError *statusError = [NSError errorWithDomain:MMEErrorDomain code:MMEUnexpectedResponseError userInfo:userInfo];
    return statusError;
}

- (NSURLRequest *)requestForConfiguration {
    
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsConfigPath, [self accessToken]];
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:MMEAPIClientBaseAPIURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:self.userAgent forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:MMEAPIClientHeaderFieldContentTypeValue forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodGet];
    
    return request;
}

- (NSURLRequest *)requestForBinary:(NSData *)binaryData boundary:(NSString *)boundary {
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientAttachmentsPath, [self accessToken]];
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *contentType = [NSString stringWithFormat:@"%@; boundary=\"%@\"",MMEAPIClientAttachmentsHeaderFieldContentTypeValue,boundary];
    
    [request setValue:self.userAgent forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:contentType forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];
    
    [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
    [request setHTTPBody:binaryData];
    
    return request;
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

    NSError* jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:&jsonError];

    if (jsonData) { // we were able to convert the eventAttrubutes, attempt compresison
        // Compressing less than 2 events can have a negative impact on the size.
        if (events.count >= 2) {
            NSData *compressedData = [jsonData mme_gzippedData];
            [request setValue:@"gzip" forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
            [request setHTTPBody:compressedData];
        } else {
            [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
            [request setHTTPBody:jsonData];
        }
    } else if (jsonError) {
        [[MMEEventsManager sharedManager] pushEvent:[MMEEvent debugEventWithError:jsonError]];

        return nil;
    }
    
    return [request copy];
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    if (UTI == NULL) {
        return nil;
    }
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    
    CFRelease(UTI);
    
    return mimetype;
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary metadata:(NSArray *)metadata filePaths:(NSArray *)filePaths {
    NSMutableData *httpBody = [NSMutableData data];
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:metadata options:0 error:&jsonError];

    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"attachments\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

    if (jsonData) { // add json metadata part
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: application/json\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:jsonData];
        [httpBody appendData:[[NSString stringWithFormat:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if (jsonError) {
        [[MMEEventsManager sharedManager] pushEvent:[MMEEvent debugEventWithError:jsonError]];
    }

    for (NSString *path in filePaths) { // add a file part for each
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];

        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
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
