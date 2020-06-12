#import "MMENSURLRequestFactory.h"
#import "MMEConfigurationProviding.h"
#import "MMEConstants.h"
#import "NSData+MMEGZIP.h"
#import "MMEEvent.h"

static NSString * const MMEMapboxAgent = @"X-Mapbox-Agent";

@interface MMENSURLRequestFactory ()
@property (nonatomic, copy) NSDictionary<NSString*, NSString*>* defaultHeaders;
@end

// Factory for building Requests with shared components
@implementation MMENSURLRequestFactory

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config {
    self = [super init];
    if (self) {
        _config = config;
        _defaultHeaders = @{
            MMEAPIClientHeaderFieldContentTypeKey: MMEAPIClientHeaderFieldContentTypeValue
        };
    }
    return self;
}

// General Purpose
- (nullable NSURLRequest*)urlRequestWithMethod:(NSString*)method
                                       baseURL:(NSURL*)baseURL
                                          path:(NSString*)path
                             additionalHeaders:(NSDictionary<NSString*, NSString*>*)additionalHeaders
                                    shouldGZIP: (BOOL) shouldGZip
                                          jsonObject: (nullable id)jsonObject
                                         error:(NSError **)error {

    NSMutableDictionary<NSString*, NSString*>* headers = [additionalHeaders mutableCopy];
    NSData* data;
    if (jsonObject) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:error];
        if (jsonData) {
            if (shouldGZip) {
                data = [jsonData mme_gzippedData];
                headers[MMEAPIClientHeaderFieldContentEncodingKey] = @"gzip";
            } else {
                data = jsonData;
            }
        }
    }

    return [self urlRequestWithMethod:method
                              baseURL:baseURL
                                 path:path
                    additionalHeaders:[headers copy]
                             httpBody:data];
}

- (nullable NSURLRequest*)multipartURLRequestWithMethod:(NSString*)method
                                                baseURL:(NSURL*)baseURL
                                                   path:(NSString*)path
                                      additionalHeaders:(NSDictionary<NSString*, NSString*>*)additionalHeaders
                                                   data:(NSData*)data
                                               boundary:(NSString *)boundary {

    NSMutableDictionary<NSString*, NSString*>* headers = [additionalHeaders mutableCopy];
    NSString *contentType = [NSString stringWithFormat:@"%@; boundary=\"%@\"",MMEAPIClientAttachmentsHeaderFieldContentTypeValue,boundary];
    headers[MMEAPIClientHeaderFieldContentTypeKey] = contentType;
    headers[MMEAPIClientHeaderFieldContentEncodingKey] = nil;

    return [self urlRequestWithMethod:method baseURL:baseURL path:path additionalHeaders:additionalHeaders httpBody:data];


}

- (nullable NSURLRequest*)urlRequestWithMethod:(NSString*)method
                                       baseURL:(NSURL*)baseURL
                                          path:(NSString*)path
                             additionalHeaders:(NSDictionary<NSString*, NSString*>*)additionalHeaders
                                      httpBody: (NSData*)data {

    // Build Headers (First with Defaults
    NSMutableDictionary<NSString*, NSString*>* headers = [self.defaultHeaders mutableCopy];
    [headers addEntriesFromDictionary:additionalHeaders];

    // Build URL
    NSURL* url = [baseURL URLByAppendingPathComponent:path];
    if (url == nil) {
        return nil;
    }

    // Construct Query Params vis Query Items
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"access_token" value: self.config.accessToken]
    ];

    url = components.URL;
    if (url == nil) {
        return nil;
    }

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];

    // Set additional Headers (Include Defaults)
    [request setAllHTTPHeaderFields:headers];

    // Set UserAgent Separately to ensure not overwritted
    [request setValue:self.config.userAgentString forHTTPHeaderField:MMEMapboxAgent];
    [request setValue:self.config.legacyUserAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];

    if (data) {
        [request setHTTPBody:data];
    }

    // Construct URLRequest
    return [request copy];
}

// MARK: - Events
- (nullable NSURLRequest *)requestForEvents:(NSArray *)events error:(NSError**)serializationError {

    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];

    NSDictionary<NSString*, NSString*>* additionalHeaders = @{
        MMEAPIClientHeaderFieldContentTypeKey: MMEAPIClientHeaderFieldContentTypeValue
    };

    NSURLRequest* request = [self urlRequestWithMethod:MMEAPIClientHTTPMethodPost
                                                              baseURL:self.config.eventsServiceURL
                                                                 path:MMEAPIClientEventsPath
                                                    additionalHeaders:additionalHeaders
                                                           shouldGZIP: events.count >= 2
                                                           jsonObject:eventAttributes
                                                                error:serializationError];

    return request;
}

// MARK: - Event Configuration

- (nullable NSURLRequest *)requestForConfiguration {
    NSError *jsonError = nil;
    return [self urlRequestWithMethod:MMEAPIClientHTTPMethodPost
                                             baseURL:self.config.configServiceURL
                                                path:MMEAPIClientEventsConfigPath
                                   additionalHeaders:@{}
                                          shouldGZIP: NO
                                          jsonObject:nil
                                               error:&jsonError];
    
}
@end
