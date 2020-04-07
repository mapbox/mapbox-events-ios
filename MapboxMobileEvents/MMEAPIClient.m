#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEMetricsManager.h"
#import "MMEEventsManager.h"
#import "MMEEventsManager_Private.h"
#import "MMELogger.h"

#import "NSData+MMEGZIP.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"

static NSString * const MMEMapboxAgent = @"X-Mapbox-Agent";

typedef NS_ENUM(NSInteger, MMEErrorCode) {
    MMESessionFailedError,
    MMEUnexpectedResponseError
};

@import MobileCoreServices;

// MARK: -

@interface MMEAPIClient ()
@property (nonatomic) NSTimer *configurationUpdateTimer;
@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;

@end

int const kMMEMaxRequestCount = 1000;

// MARK: -

@implementation MMEAPIClient

- (instancetype)initWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion {
    self = [super init];
    if (self) {
        [NSUserDefaults.mme_configuration mme_setAccessToken:accessToken];
        [NSUserDefaults.mme_configuration mme_setLegacyUserAgentBase:userAgentBase];
        [NSUserDefaults.mme_configuration mme_setLegacyHostSDKVersion:hostSDKVersion];
        _sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
        [self startGettingConfigUpdates];
    }
    return self;
}

- (void) dealloc {
    [self stopGettingConfigUpdates];
    [self.sessionWrapper invalidate];
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

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    [MMEMetricsManager.sharedManager updateMetricsFromEventQueue:events];
    
    NSArray *eventBatches = [self batchFromEvents:events];
    
    for (NSArray *batch in eventBatches) {
        NSURLRequest *request = [self requestForEvents:batch];
        if (request) {
            [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                // check the response object for HTTP error code
                if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    NSError *statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse sessionError:error];

                    if (statusError) { // report the status error
                        [MMEEventsManager.sharedManager reportError:statusError];
                    }

                    // check the data object, log the Rx bytes and try to load the config
                    if (data) {
                        [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
                    }
                }
                else if (error) { // check the session error and report it if the response appears invalid
                    [MMEEventsManager.sharedManager reportError:error];
                }
                
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

// MARK: - Metadata Service

- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler {
    NSString *boundary = NSUUID.UUID.UUIDString;
    NSData *binaryData = [self createBodyWithBoundary:boundary metadata:metadata filePaths:filePaths];
    NSURLRequest *request = [self requestForBinary:binaryData boundary:boundary];
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        // check the response object for HTTP error code
        if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSError *statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse sessionError:error];
            
            if (statusError) { // always report the status error
                [MMEEventsManager.sharedManager reportError:statusError];
            }
            
            if (data) { // always log the Rx bytes
                [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
            }
        }
        else if (error) { // check the session error and report it if the response appears invalid
            [MMEEventsManager.sharedManager reportError:error];
        }

        [MMEMetricsManager.sharedManager updateMetricsFromEventCount:filePaths.count request:request error:error];
        [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
        
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

// MARK: - Configuration Service

- (void)startGettingConfigUpdates {
    if (self.isGettingConfigUpdates) {
        [self stopGettingConfigUpdates];
    }

    if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) {
        self.configurationUpdateTimer = [NSTimer
            scheduledTimerWithTimeInterval:NSUserDefaults.mme_configuration.mme_configUpdateInterval
            repeats:YES
            block:^(NSTimer * _Nonnull timer) {
                NSURLRequest *request = [self requestForConfiguration];
                
                [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
<<<<<<< HEAD

                    // first, check the session error and report it
                    if (error) {
                        [MMEEventsManager.sharedManager reportError:error];
                    }
                    
<<<<<<< HEAD
                    if (statusError) {
                        [MMEEventsManager.sharedManager reportError:statusError];
                    }
                    else if (data) {
                        NSError *configError = [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
                        if (configError) {
                            [MMEEventsManager.sharedManager reportError:configError];
=======
                    // check the response object for HTTP error code, update the local clock offset
=======
                    // check the response object for HTTP error code
>>>>>>> Make error handling and reporting more consistent for all the network calls
                    if (response && [response isKindOfClass:NSHTTPURLResponse.class]) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                        NSError *statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse sessionError:error];

                        if (!statusError) {
                            // check for time-offset from the server
                            NSString *dateHeader = httpResponse.allHeaderFields[@"Date"];
                            if (dateHeader) {
                                // parse the server date, compute the offset
                                NSDate *date = [MMEDate.HTTPDateFormatter dateFromString:dateHeader];
                                if (date) {
                                    [MMEDate recordTimeOffsetFromServer:date];
                                } // else failed to parse date
                            }

                            // check the data object, log the Rx bytes and try to load the config
                            if (data) {
                                [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];

                                NSError *configError = [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:(NSData * _Nonnull)data];
                                if (configError) {
                                    [MMEEventsManager.sharedManager reportError:configError];
                                }
                                
                                NSUserDefaults.mme_configuration.mme_configUpdateDate = MMEDate.date;
                            }
>>>>>>> Check for and report errors from the session wrapper
                        }
                        else {
                            [MMEEventsManager.sharedManager reportError:statusError];
                        }
                    }
                    else if (error) { // check the session error and report it if the response appears invalid
                        [MMEEventsManager.sharedManager reportError:error];
                    }

                    [MMEMetricsManager.sharedManager updateMetricsFromEventCount:0 request:request error:error];
                    [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
                }];
            }];
        
        // be power conscious and give this timer a minute of slack so it can be coalesced
        self.configurationUpdateTimer.tolerance = 60;

        // check to see if time since the last update is greater than our update interval
        if (!NSUserDefaults.mme_configuration.mme_configUpdateDate // we've never updated
         || (fabs(NSUserDefaults.mme_configuration.mme_configUpdateDate.timeIntervalSinceNow)
          > NSUserDefaults.mme_configuration.mme_configUpdateInterval)) { // or it's been a while
            [self.configurationUpdateTimer fire]; // update now
        }
    }
}

- (void)stopGettingConfigUpdates {
    [self.configurationUpdateTimer invalidate];
    self.configurationUpdateTimer = nil;
}

- (BOOL)isGettingConfigUpdates {
    return self.configurationUpdateTimer.isValid;
}

// MARK: - Utilities

- (NSError *)statusErrorFromRequest:(NSURLRequest *)request andHTTPResponse:(NSHTTPURLResponse *)httpResponse sessionError:(NSError *)error {
    NSError *statusError = nil;
<<<<<<< HEAD
    if (httpResponse.statusCode >= 400) {
        NSString *descriptionFormat = @"The session data task failed. Original request was: %@";
        NSString *reasonFormat = @"The status code was %ld";
        NSString *description = [NSString stringWithFormat:descriptionFormat, request ?: [NSNull null]];
        NSString *reason = [NSString stringWithFormat:reasonFormat, (long)httpResponse.statusCode];
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
=======
    if (httpResponse.statusCode >= 400) { // all 4xx and 5xx errors should be reported
        NSString *description = [NSString stringWithFormat:@"The session data task failed. Original request was: %@",
            request ?: [NSNull null]];
        NSString *reason = [NSString stringWithFormat:@"The status code was %ld", (long)httpResponse.statusCode];
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
>>>>>>> Make error handling and reporting more consistent for all the network calls
        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:reason forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setValue:httpResponse forKey:MMEResponseKey];
        if (error) { // record the session error as the underlying error
            [userInfo setValue:error forKey:NSUnderlyingErrorKey];
        }
        
        statusError = [NSError errorWithDomain:MMEErrorDomain code:MMESessionFailedError userInfo:userInfo];
    }
    return statusError;
}

<<<<<<< HEAD
- (NSError *)unexpectedResponseErrorFromRequest:(nonnull NSURLRequest *)request andResponse:(NSURLResponse *)response {
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

=======
>>>>>>> Make error handling and reporting more consistent for all the network calls
- (NSURLRequest *)requestForConfiguration {
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsConfigPath, NSUserDefaults.mme_configuration.mme_accessToken];
    NSURL *configServiceURL = [NSURL URLWithString:path relativeToURL:NSUserDefaults.mme_configuration.mme_configServiceURL];
    NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:configServiceURL];
    
    [request setValue:NSUserDefaults.mme_configuration.mme_userAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:MMEAPIClientHeaderFieldContentTypeValue forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];
    
    return request;
}

- (NSURLRequest *)requestForBinary:(NSData *)binaryData boundary:(NSString *)boundary {
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientAttachmentsPath, NSUserDefaults.mme_configuration.mme_accessToken];
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:NSUserDefaults.mme_configuration.mme_eventsServiceURL];
    NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:url];
    
    NSString *contentType = [NSString stringWithFormat:@"%@; boundary=\"%@\"",MMEAPIClientAttachmentsHeaderFieldContentTypeValue,boundary];
    
    [request setValue:NSUserDefaults.mme_configuration.mme_userAgentString forHTTPHeaderField:MMEMapboxAgent];
    [request setValue:NSUserDefaults.mme_configuration.mme_legacyUserAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:contentType forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];
    
    [request setValue:nil forHTTPHeaderField:MMEAPIClientHeaderFieldContentEncodingKey];
    [request setHTTPBody:binaryData];
    
    return request;
}

- (NSURLRequest *)requestForEvents:(NSArray *)events {
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsPath, NSUserDefaults.mme_configuration.mme_accessToken];

    NSURL *url = [NSURL URLWithString:path relativeToURL:NSUserDefaults.mme_configuration.mme_eventsServiceURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setValue:NSUserDefaults.mme_configuration.mme_userAgentString forHTTPHeaderField:MMEMapboxAgent];
    [request setValue:NSUserDefaults.mme_configuration.mme_legacyUserAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
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

    if (jsonData) { // we were able to convert the eventAttributes, attempt compression
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
        [MMELogger.sharedLogger logEvent:[MMEEvent debugEventWithError:jsonError]];
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
        [MMELogger.sharedLogger logEvent:[MMEEvent debugEventWithError:jsonError]];
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
