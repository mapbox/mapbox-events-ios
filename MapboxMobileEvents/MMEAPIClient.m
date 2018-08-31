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
        
        [self setBaseURL:[NSURL URLWithString:@"https://api-events-staging.tilestream.net"]];
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

- (void)postBinaries:(NSArray *)binaries completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSURLRequest *request = [self requestForBinaries:binaries];
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

- (NSURLRequest *)requestForBinaries:(NSArray *)binaries {

    //TESTING
    //Object
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"143.13-144.13" ofType:@"mp4"];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Cat" ofType:@"jpg"];
//    NSDictionary *nameDic = @{@"name": @"143.13-144.13.mp4"};
//    NSDictionary *metadata = @{@"format":@"jpg",@"eventId":@"123",@"created":@"2018-08-28T16:36:39+00:00",@"type":@"image",@"name":@"Cat.jpg"};
    NSDictionary *thingDict = @{@"name":@"143.13-144.13.mp4",
                                @"format":@"mp4",
                                @"eventId":@"123",
                                @"created":@"2018-08-28T16:36:39+00:00",
                                @"size":@"68772",
                                @"type":@"video",
                                @"startTime":@"2018-08-28T16:36:39+00:00",
                                @"endTime":@"2018-08-28T16:36:40+00:00"
                                };
//    NSString *metaString = [NSString stringWithFormat:@"{\"name\":\"143.13-144.13.mp4\",\"format\":\"mp4\",\"eventId\":\"123\",\"created\":\"2018-08-28T16:36:39+00:00\",\"size\":68772,\"type\":\"video\",\"startTime\":\"2018-08-28T16:36:39+00:00\",\"endTime\":\"2018-08-28T16:36:40+00:00\"}"];
    NSArray *metaArray = @[thingDict];
    NSDictionary *attachment = @{@"attachments":metaArray};
    //Object
//    NSMutableData *testData = [NSMutableData dataWithContentsOfFile:filePath];
    //TESTING
    
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientAttachmentsPath, [self accessToken]];
    
//    NSURL *url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:MMEAPIClientBaseURL]];
    NSURL *url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:@"https://api-events-staging.tilestream.net"]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSString *contentType = [NSString stringWithFormat:@"%@; boundary=\"%@\"",MMEAPIClientAttachmentsHeaderFieldContentTypeValue,boundary];
    
    [request setValue:self.userAgent forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:contentType forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];
    
    NSData *httpBody = [self createBodyWithBoundary:boundary parameters:attachment filePaths:@[filePath]];
    
    [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
    [request setHTTPBody:httpBody];
    
    return request;
}

//- (NSData *)dataFromBinaries:(NSArray *)binaries {
//    //TODO: parse binaries or accept binaries from Vision as an array of filepaths and array of metadata
//}

- (NSData *)createBodyWithBoundary:(NSString *)boundary parameters:(NSDictionary *)parameters filePaths:(NSArray *)filePaths {
    NSMutableData *httpBody = [NSMutableData data];
    
    for (NSString *path in filePaths) {
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
//                [httpBody appendData:[[NSString stringWithFormat:@"...some nice image content..."] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: application/json\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//        NSError *jsonError = nil;
//        [httpBody appendData:[[NSString stringWithFormat:@"[{\"name\":\"143.13-144.13.mp4\"}]"] dataUsingEncoding:NSUTF8StringEncoding]];
                [httpBody appendData:[NSJSONSerialization dataWithJSONObject:parameterValue options:0 error:nil]];
        
//        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
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
