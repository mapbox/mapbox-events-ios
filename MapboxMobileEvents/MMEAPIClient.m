#import "MMEAPIClient.h"
#import "MMEConfig.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEConfigurationProviding.h"
#import "MMENSURLRequestFactory.h"
#import "MMENSURLSessionWrapper.h"

@import MobileCoreServices;

// MARK: -

/*! @Brief Private Client Properties */
@interface MMEAPIClient ()

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic, strong) id<MMEConfigurationProviding> config;

// Factory for building URLRequests with shared components provided by Config
@property (nonatomic, strong) MMENSURLRequestFactory *requestFactory;

// Event Inspection Hooks
@property (nonatomic, strong) NSMutableArray<OnSerializationError>* onSerializationErrorListeners;
@property (nonatomic, strong) NSMutableArray<OnURLResponse>* onUrlResponseListeners;
@property (nonatomic, strong) NSMutableArray<OnEventQueueUpdate>* onEventQueueUpdateListeners;
@property (nonatomic, strong) NSMutableArray<OnEventCountUpdate>* onEventCountUpdateListeners;
@property (nonatomic, strong) NSMutableArray<OnGenerateTelemetryEvent>* onGenerateTelemetryEventListeners;

@end

int const kMMEMaxRequestCount = 1000;


@implementation MMEAPIClient

// MARK: - Initializers

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config {

    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                                                eventConfiguration:config];

    return [self initWithConfig:config
                 requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session];
}

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config
                       session:(MMENSURLSessionWrapper*)session {

    return [self initWithConfig:config
            requestFactory:[[MMENSURLRequestFactory alloc] initWithConfig:config]
                        session:session];
}

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config
                requestFactory:(MMENSURLRequestFactory*)requestFactory
                       session:(MMENSURLSessionWrapper*)session {

    self = [super init];
    if (self) {
        self.config = config;
        self.requestFactory = requestFactory;
        self.sessionWrapper = session;
        self.onSerializationErrorListeners = [NSMutableArray array];
        self.onUrlResponseListeners = [NSMutableArray array];
        self.onEventQueueUpdateListeners = [NSMutableArray array];
        self.onEventCountUpdateListeners = [NSMutableArray array];
        self.onGenerateTelemetryEventListeners = [NSMutableArray array];
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
            for (OnURLResponse listener in strongSelf.onUrlResponseListeners) {
                listener(data, request, response, error);
            }

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

    // Message Listeners
    for (OnEventQueueUpdate listener in self.onEventQueueUpdateListeners) {
        listener(events);
    }

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


                    // Message Listeners of success/failure on completion
                    for (OnEventCountUpdate listener in self.onEventCountUpdateListeners) {
                        // TODO: Is this the right count to report? Should this be going down? Reference batch count vs original events array
                        listener(batch.count, request, error);
                    }

                    if (completionHandler) {
                        completionHandler(error);
                    }
                }

            }];

        } else {

            // Message Listeners on failure to send batch due to issue building Request
            for (OnEventCountUpdate listener in self.onEventCountUpdateListeners) {
                listener(batch.count, nil, nil);
            }
        }

        if (serializationError) {

            // Message Listeners
            for (OnSerializationError listener in self.onSerializationErrorListeners) {
                listener(serializationError);
            }
        }


    }

    // Message Listeners
    for (OnGenerateTelemetryEvent listener in self.onGenerateTelemetryEventListeners) {
        listener();
    }
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

                // Message Listeners
                for (OnSerializationError listener in strongSelf.onSerializationErrorListeners) {
                    listener(decodingError);
                }
            }

            // Message Listeners
            for (OnEventCountUpdate listener in strongSelf.onEventCountUpdateListeners) {
                listener(0, request, error);
            }

            for (OnGenerateTelemetryEvent listener in strongSelf.onGenerateTelemetryEventListeners) {
                listener();
            }

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

            // Message Listeners
            for (OnEventCountUpdate listener in strongSelf.onEventCountUpdateListeners) {
                listener(filePaths.count, request, error);
            }

            for (OnGenerateTelemetryEvent listener in strongSelf.onGenerateTelemetryEventListeners) {
                listener();
            }

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
        // Message Listeners
        for (OnSerializationError listener in self.onSerializationErrorListeners) {
            listener(jsonError);
        }
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

// MARK: - Observation Hooks (Logging/Metrics)

/*! @brief Block called on deserialization errors */
- (void)registerOnSerializationErrorListener:(OnSerializationError)onSerializationError {
    [self.onSerializationErrorListeners addObject:[onSerializationError copy]];
}

/*! @brief Block called on url responses  */
- (void)registerOnURLResponseListener:(OnURLResponse)onURLResponse {
    [self.onUrlResponseListeners addObject:[onURLResponse copy]];
}

/*! @brief Block called on EventQueue updates  */
- (void)registerOnEventQueueUpdate:(OnEventQueueUpdate)onEventQueueUpdate {
    [self.onEventQueueUpdateListeners addObject:[onEventQueueUpdate copy]];
}

/*! @brief Block called on EventCount Udpates  */
- (void)registerOnEventCountUpdate:(OnEventCountUpdate)onEventCountUpdate {
    [self.onEventCountUpdateListeners addObject:[onEventCountUpdate copy]];

}

/*! @brief Block called on Generation of Telemetry Events  */
- (void)registerOnGenerateTelemetryEvent:(OnGenerateTelemetryEvent)onGenerateTelemetryEvent {
    [self.onGenerateTelemetryEventListeners addObject:[onGenerateTelemetryEvent copy]];
}

@end
