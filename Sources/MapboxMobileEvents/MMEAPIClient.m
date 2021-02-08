#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"
#import "MMEConstants.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEDate.h"
#import "MMEEvent.h"
#import "MMEMetricsManager.h"
#import "MMEEventsManager.h"
#import "MMEEventsManager_Private.h"
#import "MMEEventLogger.h"

#import "NSData+MMEGZIP.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"

static NSString * const MMEMapboxAgent = @"X-Mapbox-Agent";

typedef NS_ENUM(NSInteger, MMEErrorCode) {
    MMESessionFailedError,
    MMEUnexpectedResponseError
};

@import MobileCoreServices;

#pragma mark -

@interface MMEAPIClient ()
@property (nonatomic) NSTimer *configurationUpdateTimer;
@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) NSBundle *applicationBundle;

@end

int const kMMEMaxRequestCount = 1000;

#pragma mark -

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
    NSUInteger eventsRemaining = [events count];
    NSUInteger i = 0;
    
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
            [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable requestError) {
                [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
                
                NSError *responseError = nil;
                if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    responseError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
                } else {
                    responseError = [self unexpectedResponseError:requestError fromRequest:request andResponse:response];
                }
                
                [MMEMetricsManager.sharedManager updateMetricsFromEventCount:events.count request:request error:(responseError ?: requestError)];
                
                if (completionHandler) {
                    if (responseError) {
                        completionHandler(responseError);
                    }
                    else {
                        completionHandler(requestError);
                    }
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

// MARK: - Configuration Service
void MMEDispatchMainIfNeeded(void (^block)(void))
{
    if ([NSThread isMainThread]) { block(); }
    else { dispatch_sync(dispatch_get_main_queue(), block); }
}

- (void)startGettingConfigUpdates {
    if (self.isGettingConfigUpdates) {
        [self stopGettingConfigUpdates];
    }

    if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) {
        self.configurationUpdateTimer = [NSTimer
                                         scheduledTimerWithTimeInterval:NSUserDefaults.mme_configuration.mme_configUpdateInterval
                                         repeats:YES
                                         block:^(NSTimer * _Nonnull timer) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(queue, ^{
                NSURLRequest *request = [self requestForConfiguration];
                MMEDispatchMainIfNeeded(^{
                    [self processRequest:request];
                });
            });
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

+ (nullable NSString *)parseDigestHeader:(NSString *)digestHeader {
    NSString *digest = nil;
    if (digestHeader) {
        // Look for 'SHA-256' hash in case of multiple different digest values
        NSArray *kvs = [digestHeader componentsSeparatedByString:@","];
        if (kvs.count >= 2) {
            for (NSString *field in kvs) {
                NSArray *keyValue = [field componentsSeparatedByString:@"SHA-256="];
                if (keyValue.count == 2) {
                    digest = keyValue[1];
                }
            }
        } else {
            // In case of single digest value, look for the 'SHA-256' hash, and
            // fallback to the value received from the config service assuming
            // that the Digest: header comes from a 1.0 config service has just
            // a hash value.
            digest = [digestHeader componentsSeparatedByString:@"SHA-256="].lastObject;
        }
    }
    return digest;
}

- (void)processRequest:(NSURLRequest *)request {
    [self.sessionWrapper processRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [MMEMetricsManager.sharedManager updateReceivedBytes:data.length];
        NSHTTPURLResponse *httpResponse = nil;
        NSError *statusError = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *)response;
            statusError = [self statusErrorFromRequest:request andHTTPResponse:httpResponse];
        } else {
            statusError = [self unexpectedResponseError:error fromRequest:request andResponse:response];
        }

        if (statusError) {
            [MMEEventsManager.sharedManager reportError:statusError];
        }
        else if (data) {
            NSError *configError = [NSUserDefaults.mme_configuration mme_updateFromConfigServiceData:data];
            if (configError) {
                [MMEEventsManager.sharedManager reportError:configError];
            }

            // check for time-offset from the server
            NSString *dateHeader = httpResponse.allHeaderFields[@"Date"];
            if (dateHeader) {
                // parse the server date, compute the offset
                NSDate *date = [MMEDate.HTTPDateFormatter dateFromString:dateHeader];
                if (date) {
                    [MMEDate recordTimeOffsetFromServer:date];
                } // else failed to parse date
            }

            NSUserDefaults.mme_configuration.mme_configUpdateDate = MMEDate.date;

            NSString* digest = [self.class parseDigestHeader:httpResponse.allHeaderFields[@"Digest"]];
            [NSUserDefaults.mme_configuration mme_setConfigDigestValue:digest];
        }

        [MMEMetricsManager.sharedManager updateMetricsFromEventCount:0 request:request error:error];
        [MMEMetricsManager.sharedManager generateTelemetryMetricsEvent];
    }];
}

- (void)stopGettingConfigUpdates {
    [self.configurationUpdateTimer invalidate];
    self.configurationUpdateTimer = nil;
}

- (BOOL)isGettingConfigUpdates {
    return self.configurationUpdateTimer.isValid;
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

- (NSError *)unexpectedResponseError:(NSError*) error fromRequest:(nonnull NSURLRequest *)request andResponse:(id)response {
    NSString *description = [NSString stringWithFormat:@"The session data task failed eith error: %@ request: %@ response: %@", error, request, response];
    NSString *reason = @"Unexpected response";
    NSMutableDictionary *userInfo = NSMutableDictionary.new;
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:reason forKey:NSLocalizedFailureReasonErrorKey];
    [userInfo setValue:response forKey:MMEResponseKey];
    if (error) {
        [userInfo setValue:error forKey:NSUnderlyingErrorKey];
    }
    
    NSError *statusError = [NSError errorWithDomain:MMEErrorDomain code:MMEUnexpectedResponseError userInfo:userInfo];
    return statusError;
}

- (NSURLRequest *)requestForConfiguration {
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsConfigPath, NSUserDefaults.mme_configuration.mme_accessToken];
    NSURL *configServiceURL = [NSURL URLWithString:path relativeToURL:NSUserDefaults.mme_configuration.mme_configServiceURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:configServiceURL];
    
    [request setValue:NSUserDefaults.mme_configuration.mme_userAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:MMEAPIClientHeaderFieldContentTypeValue forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];
    
    NSDictionary *jsonDict = @{MMEClientId: NSUserDefaults.mme_configuration.mme_clientId};
    NSError* jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&jsonError];
    if (jsonData) {
        [request setHTTPBody:jsonData];
    } else if (jsonError) {
        [MMEEventsManager.sharedManager reportError:jsonError];
        return nil;
    }

    return request;
}

- (NSURLRequest *)requestForBinary:(NSData *)binaryData boundary:(NSString *)boundary {
    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientAttachmentsPath, NSUserDefaults.mme_configuration.mme_accessToken];
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:NSUserDefaults.mme_configuration.mme_eventsServiceURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
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
        [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:jsonError]];
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
        [MMEEventLogger.sharedLogger logEvent:[MMEEvent debugEventWithError:jsonError]];
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
