#import "MMEAPIClient.h"
#import "MMEConfig.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEEventConfigProviding.h"
#import "MMENSURLRequestFactory.h"
#import "MMENSURLSessionWrapper.h"

@import MobileCoreServices;

// MARK: -

/*! @Brief Private Client Properties */
@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic, strong) id<MMEEventConfigProviding> config;

// Factory for building URLRequests with shared components provided by Config
@property (nonatomic, strong) MMENSURLRequestFactory *requestFactory;

// Metrics and statistics gathering hooks (Likely eligible to move to a private hader)
@property (nonatomic, copy) OnSerializationError onSerializationError;
@property (nonatomic, copy) OnURLResponse onURLResponse;
@property (nonatomic, copy) OnEventQueueUpdate onEventQueueUpdate;
@property (nonatomic, copy) OnEventCountUpdate onEventCountUpdate;
@property (nonatomic, copy) OnGenerateTelemetryEvent onGenerateTelemetryEvent;
@end

int const kMMEMaxRequestCount = 1000;


@implementation MMEAPIClient

// MARK: - Initializers

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config {

    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                                                eventConfiguration:config];

    return [self initWithConfig:config
                 requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session];
}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                       session:(MMENSURLSessionWrapper*)session {

    return [self initWithConfig:config
            requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session];
}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                requestFactory:(MMENSURLRequestFactory*)requestFactory
                       session:(MMENSURLSessionWrapper*)session {

    return [self initWithConfig:config
                 requestFactory:requestFactory
                        session:session
           onSerializationError:^(NSError * _Nonnull error) {}
                  onURLResponse:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {} onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {}
             onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {} onGenerateTelemetryEvent:^{}];
}

/// Initializer with Default Request Feactory
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
          onSerializationError:(OnSerializationError)onSerializationError
                 onURLResponse:(OnURLResponse)onURLResponse
            onEventQueueUpdate: (OnEventQueueUpdate)onEventQueueUpdate
            onEventCountUpdate: (OnEventCountUpdate)onEventCountUpdate
      onGenerateTelemetryEvent: (OnGenerateTelemetryEvent)onGenerateTelemetryEvent {

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:config];
    
    return [self initWithConfig:config
                 requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session
           onSerializationError:onSerializationError
                  onURLResponse:onURLResponse
             onEventQueueUpdate:onEventQueueUpdate
             onEventCountUpdate:onEventCountUpdate
       onGenerateTelemetryEvent:onGenerateTelemetryEvent];

}

/// Designated Initializer containing all dependencies
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                requestFactory:(MMENSURLRequestFactory*)requestFactory
                       session:(MMENSURLSessionWrapper*)session
          onSerializationError:(OnSerializationError)onSerializationError
                 onURLResponse:(OnURLResponse)onURLResponse
            onEventQueueUpdate: (OnEventQueueUpdate)onEventQueueUpdate
            onEventCountUpdate: (OnEventCountUpdate)onEventCountUpdate
      onGenerateTelemetryEvent: (OnGenerateTelemetryEvent)onGenerateTelemetryEvent {

    self = [super init];
    if (self) {
        self.config = config;
        self.requestFactory = requestFactory;
        self.sessionWrapper = session;
        self.onSerializationError = onSerializationError;
        self.onURLResponse = onURLResponse;
        self.onEventQueueUpdate = onEventQueueUpdate;
        self.onEventCountUpdate = onEventCountUpdate;
        self.onGenerateTelemetryEvent = onGenerateTelemetryEvent;
    }
    return self;
}

- (void) dealloc {
    [self.sessionWrapper invalidate];
}

// MARK: - Requests

/** Designated Method to perform any API request. All requests should flow through here for shared general metric logging */
- (void)performRequest:(NSURLRequest*)request
     completion:(nullable void (^)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completion {

    __weak __typeof__(self) weakSelf = self;

    // General Request
    [self.sessionWrapper processRequest:request
                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {

            // Report Each URL Response for general Reporting
            strongSelf.onURLResponse(data, request, response, error);

            // Inspect for General Response Reporting
            if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

                if (completion) {
                    completion(data, httpResponse, error);
                }
            }
            else if (error) {

                if (completion) {
                    completion(data, nil, error);
                }
            }
        }
    }];
}

// MARK: - Events Service

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

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self postEvents:@[event] completionHandler:completionHandler];
}

- (void)postEvents:(NSArray <MMEEvent*> *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {

    self.onEventQueueUpdate(events);

    NSArray *eventBatches = [self batchFromEvents:events];

    for (NSArray *batch in eventBatches) {
        NSError* serializationError = nil;
        NSURLRequest *request = [self.requestFactory requestForEvents:batch error:&serializationError];

        if (request) {

            __weak __typeof__(self) weakSelf = self;
            [self performRequest:request
                      completion:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {

                __strong __typeof__(weakSelf) strongSelf = weakSelf;
                if (strongSelf) {

                    // TODO: Is this supposed to track the batch sent? Or the original events array?
                    // If this is tracking on completion of request, batch would be the appropriate model
                    strongSelf.onEventCountUpdate(batch.count, request, error);

                    if (completionHandler) {
                        completionHandler(error);
                    }
                }

            }];
        }

        if (serializationError) {
            self.onSerializationError(serializationError);
        }

        self.onEventCountUpdate(events.count, nil, nil);
    }

    self.onGenerateTelemetryEvent();
}

// MARK: - Configuration Service

- (void)getEventConfigWithCompletionHandler:(nullable void (^)(MMEConfig* _Nullable config, NSError * _Nullable error))completion {

    NSURLRequest* request = [self.requestFactory requestForConfiguration];

    __weak __typeof__(self) weakSelf = self;
    [self performRequest:request
              completion:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {

        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (error) {
                completion(nil, error);
                return;
            }

            // Inspect Header for TimeOffset from server
            NSString *dateHeader = response.allHeaderFields[@"Date"];
            if (dateHeader){
                NSDate *date = [MMEDate.HTTPDateFormatter dateFromString:dateHeader];
                if (date) {
                    // TODO: Do we need to record this if we don't get data?
                    [MMEDate recordTimeOffsetFromServer:date];
                }
            }

            NSDictionary<NSString*, id <NSObject>>* json = nil;
            NSError *decodingError = nil;
            MMEConfig* config = nil;

            // Decode Data
            if (data) {
                json = [NSJSONSerialization JSONObjectWithData:data
                                                       options:kNilOptions
                                                         error:&decodingError];

                // Map to MMEConfig
                if (json) {
                    config = [[MMEConfig alloc] initWithDictionary:json error:&decodingError];
                }
            }

            // Error Metric Reporting
            if (decodingError) {
                strongSelf.onSerializationError(decodingError);
            }

            strongSelf.onEventCountUpdate(0, request, error);
            strongSelf.onGenerateTelemetryEvent();

            completion(config, decodingError);
        }
    }];
}

// MARK: - Metadata Service

- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths
   completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSString *boundary = NSUUID.UUID.UUIDString;
    NSData *binaryData = [self createBodyWithBoundary:boundary metadata:metadata filePaths:filePaths];
    NSURLRequest* request = [self.requestFactory multipartURLRequestWithMethod:MMEAPIClientHTTPMethodPost
                                                                       baseURL:self.config.eventsServiceURL
                                                                          path:MMEAPIClientAttachmentsPath
                                                             additionalHeaders:@{}
                                                                          data:binaryData
                                                                      boundary:boundary];

    __weak __typeof__(self) weakSelf = self;

    [self performRequest:request
              completion:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {

        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {

            strongSelf.onEventCountUpdate(filePaths.count, request, error);
            strongSelf.onGenerateTelemetryEvent();

            if (completionHandler) {
                completionHandler(error);
            }
        }
    }];
}


// MARK: - Utilities

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
        self.onSerializationError(jsonError);
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

@end
