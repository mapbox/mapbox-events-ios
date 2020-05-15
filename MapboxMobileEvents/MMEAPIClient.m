#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMEConfig.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEEventConfigProviding.h"
#import "MMENSURLRequestFactory.h"
#import "MMENSURLSessionWrapper.h"
#import "NSError+APIClient.h"

@import MobileCoreServices;

// MARK: -

/*! @Brief Private Client Properties */
@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;

// Factory for building URLRequests with shared components provided by Config
@property (nonatomic, readonly) MMENSURLRequestFactory *requestFactory;

// Metrics and statistics gathering hooks (Likely eligible to move to a private hader)
@property (nonatomic, copy) OnErrorBlock onError;
@property (nonatomic, copy) OnBytesReceived onBytesReceived;
@property (nonatomic, copy) OnEventQueueUpdate onEventQueueUpdate;
@property (nonatomic, copy) OnEventCountUpdate onEventCountUpdate;
@property (nonatomic, copy) OnGenerateTelemetryEvent onGenerateTelemetryEvent;
@property (nonatomic, copy) OnLogEvent onLogEvent;
@end

int const kMMEMaxRequestCount = 1000;


@implementation MMEAPIClient

// MARK: - Initializers

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config {

    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                                                eventConfiguration:config];
    return [self initWithConfig:config
                 requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session
                        onError:^(NSError * _Nonnull error) {}
                onBytesReceived:^(NSUInteger bytes) {} onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {}
             onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {}
       onGenerateTelemetryEvent:^{}
                     onLogEvent:^(MMEEvent * _Nonnull event) {}];

}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                       session:(MMENSURLSessionWrapper*)session {

    return [self initWithConfig:config
                 requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session
                        onError:^(NSError * _Nonnull error) {}
                onBytesReceived:^(NSUInteger bytes) {} onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {}
             onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {}
       onGenerateTelemetryEvent:^{}
                     onLogEvent:^(MMEEvent * _Nonnull event) {}];
}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                       onError: (OnErrorBlock)onError
               onBytesReceived: (OnBytesReceived)onBytesReceived
            onEventQueueUpdate: (OnEventQueueUpdate)onEventQueueUpdate
            onEventCountUpdate: (OnEventCountUpdate)onEventCountUpdate
      onGenerateTelemetryEvent: (OnGenerateTelemetryEvent)onGenerateTelemetryEvent
                    onLogEvent: (OnLogEvent)onLogEvent {

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:config];
    
    return [self initWithConfig:config
                 requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session
                        onError:onError
                onBytesReceived:onBytesReceived
             onEventQueueUpdate:onEventQueueUpdate
             onEventCountUpdate:onEventCountUpdate
       onGenerateTelemetryEvent:onGenerateTelemetryEvent
                     onLogEvent:onLogEvent];

}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                requestFactory:(MMENSURLRequestFactory*)requestFactory
                       session:(MMENSURLSessionWrapper*)session
                       onError: (OnErrorBlock)onError
               onBytesReceived: (OnBytesReceived)onBytesReceived
            onEventQueueUpdate: (OnEventQueueUpdate)onEventQueueUpdate
            onEventCountUpdate: (OnEventCountUpdate)onEventCountUpdate
      onGenerateTelemetryEvent: (OnGenerateTelemetryEvent)onGenerateTelemetryEvent
                    onLogEvent: (OnLogEvent)onLogEvent {

    self = [super init];
    if (self) {
        _config = config;
        _requestFactory = requestFactory;
        _sessionWrapper = session;
        self.onError = onError;
        self.onBytesReceived = onBytesReceived;
        self.onEventQueueUpdate = onEventQueueUpdate;
        self.onEventCountUpdate = onEventCountUpdate;
        self.onGenerateTelemetryEvent = onGenerateTelemetryEvent;
        self.onLogEvent = onLogEvent;
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

            // Inspect for General Response Reporting
            if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSError *statusError = [[NSError alloc] initWith:request httpResponse:httpResponse error:error];

                // General Error Reporting
                if (statusError) {
                    strongSelf.onError(statusError);
                }

                // Report Metrics
                if (data) {
                    strongSelf.onBytesReceived(data.length);
                }

                if (completion) {
                    completion(data, httpResponse, error);
                }
            }
            else if (error) {
                // General Error Reporting
                strongSelf.onError(error);

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

- (nullable NSURLRequest *)requestForEvents:(NSArray *)events {

    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];

    NSDictionary<NSString*, NSString*>* additionalHeaders = @{
        MMEAPIClientHeaderFieldContentTypeKey: MMEAPIClientHeaderFieldContentTypeValue
    };

    NSError* jsonError = nil;
    NSURLRequest* request = [self.requestFactory urlRequestWithMethod:MMEAPIClientHTTPMethodPost
                                                              baseURL:self.config.eventsServiceURL
                                                                 path:MMEAPIClientEventsPath
                                                    additionalHeaders:additionalHeaders
                                                           shouldGZIP: events.count >= 2
                                                           jsonObject:eventAttributes
                                                                error:&jsonError];

    if (jsonError) {
        self.onLogEvent([MMEEvent debugEventWithError:jsonError]);
        return nil;
    }

    return [request copy];
}

- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [self postEvents:@[event] completionHandler:completionHandler];
}

- (void)postEvents:(NSArray <MMEEvent*> *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {

    self.onEventQueueUpdate(events);

    NSArray *eventBatches = [self batchFromEvents:events];

    for (NSArray *batch in eventBatches) {
        NSURLRequest *request = [self requestForEvents:batch];
        if (request) {

            __weak __typeof__(self) weakSelf = self;
            [self performRequest:request
                      completion:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {

                __strong __typeof__(weakSelf) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.onEventCountUpdate(events.count, request, error);

                    if (completionHandler) {
                        completionHandler(error);
                    }
                }

            }];
        }
        self.onEventCountUpdate(events.count, nil, nil);
    }

    self.onGenerateTelemetryEvent();
}

// MARK: - URLRequest Construction

- (nullable NSURLRequest *)eventConfigurationRequest {
    NSError *jsonError = nil;
    return [self.requestFactory urlRequestWithMethod:MMEAPIClientHTTPMethodPost
                                             baseURL:self.config.configServiceURL
                                                path:MMEAPIClientEventsConfigPath
                                   additionalHeaders:@{}
                                          shouldGZIP: NO
                                          jsonObject:nil
                                               error:&jsonError];
}

// MARK: - Configuration Service

- (void)getEventConfigWithCompletionHandler:(nullable void (^)(MMEConfig* _Nullable config, NSError * _Nullable error))completion {

    NSURLRequest* request = [self eventConfigurationRequest];

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
                strongSelf.onError(decodingError);
            }

            strongSelf.onEventCountUpdate(0, request, error);
            strongSelf.onGenerateTelemetryEvent();

            completion(config, decodingError);
        }
    }];
}

// MARK: - Metadata Service

- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSString *boundary = NSUUID.UUID.UUIDString;
    NSData *binaryData = [self createBodyWithBoundary:boundary metadata:metadata filePaths:filePaths];
    NSURLRequest* request = [self.requestFactory multipartURLRequestWithMethod:MMEAPIClientHTTPMethodPost
                                                                       baseURL:self.config.eventsServiceURL
                                                                          path:MMEAPIClientAttachmentsPath
                                                             additionalHeaders:@{}
                                                                          data:binaryData
                                                                      boundary:boundary];

    __weak __typeof__(self) weakSelf = self;
    [self.sessionWrapper processRequest:request
                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {

            // check the response object for HTTP error code
            if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSError *statusError = [[NSError alloc] initWith:request httpResponse:httpResponse error:error];

                if (statusError) { // always report the status error
                    strongSelf.onError(statusError);
                }

                if (data) { // always log the Rx bytes
                    strongSelf.onBytesReceived(data.length);
                }
            }
            else if (error) { // check the session error and report it if the response appears invalid
                strongSelf.onError(error);
            }

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
        self.onLogEvent([MMEEvent debugEventWithError:jsonError]);
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
