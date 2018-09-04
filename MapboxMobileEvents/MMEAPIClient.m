#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEEvent.h"
#import "NSData+MMEGZIP.h"

@import MobileCoreServices;

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

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSURLRequest *request = [self requestForEvents:events];
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *statusError = nil;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode >= 400) {
            NSString *descriptionFormat = @"The session data task failed. Original request was: %@";
            NSString *reasonFormat = @"The status code was %ld";
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

- (void)postMetadata:(NSArray *)metadata filepaths:(NSArray *)filepaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSData *binaryData = [self createBodyWithBoundary:boundary metadata:metadata filePaths:filepaths];
    NSURLRequest *request = [self requestForBinary:binaryData boundary:boundary];
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *statusError = nil;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode >= 400) {
            NSString *descriptionFormat = @"The session data task failed. Original request was: %@";
            NSString *reasonFormat = @"The status code was %ld";
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

- (NSString *)mimeTypeForPath:(NSString *)path {
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    return mimetype;
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary metadata:(NSArray *)metadata filePaths:(NSArray *)filePaths {
    NSMutableData *httpBody = [NSMutableData data];
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"attachments\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: application/json\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[NSJSONSerialization dataWithJSONObject:metadata options:0 error:nil]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    for (NSString *path in filePaths) {
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
    
    NSLog(@"httpBody: %@",[[NSString alloc] initWithData:httpBody encoding:NSUTF8StringEncoding]);
    return httpBody;
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
