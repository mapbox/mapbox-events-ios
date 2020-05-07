#import "MMENSURLRequestFactory.h"
#import "MMEEventConfigProviding.h"
#import "MMEConstants.h"
#import "NSData+MMEGZIP.h"

static NSString * const MMEMapboxAgent = @"X-Mapbox-Agent";

// Factory for building Requests with shared components
@implementation MMENSURLRequestFactory

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config {
    self = [super init];
    if (self) {
        _config = config;
    }
    return self;
}

// General Purpose
- (nullable NSURLRequest*)urlRequestWithMethod:(NSString*)method
                                       baseURL:(NSURL*)baseURL
                                          path:(NSString*)path
                             additionalHeaders:(NSDictionary<NSString*, NSString*>*)additionalHeaders
                                    shouldGZIP: (BOOL) shouldGZip
                                          jsonObject: (id)jsonObject
                                         error:(NSError **)error {

    NSMutableDictionary<NSString*, NSString*>* headers = [additionalHeaders mutableCopy];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:error];

    NSData* data;
    if (jsonData) {
        if (shouldGZip) {
            data = [jsonData mme_gzippedData];
            headers[MMEAPIClientHeaderFieldContentEncodingKey] = @"gzip";
        } else {
            data = jsonData;
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

    return [self urlRequestWithMethod:method baseURL:baseURL path:path additionalHeaders:headers httpBody:data];


}

- (nullable NSURLRequest*)urlRequestWithMethod:(NSString*)method
                                       baseURL:(NSURL*)baseURL
                                          path:(NSString*)path
                             additionalHeaders:(NSDictionary<NSString*, NSString*>*)additionalHeaders
                                      httpBody: (NSData*)data {

    // Build URL
    NSURL* url = [baseURL URLByAppendingPathComponent:path];
    if (url == nil) {
        return nil;
    }

    // Construct Query Params vis Query Items
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"access_token" value: self.config.mme_accessToken]
    ];

    url = components.URL;
    if (url == nil) {
        return nil;
    }

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];

    // Set additional Headers (Should not override defaults)
    [request setAllHTTPHeaderFields:additionalHeaders];

    // Set Defaults
    [request setValue:self.config.mme_userAgentString forHTTPHeaderField:MMEMapboxAgent];
    [request setValue:self.config.mme_legacyUserAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];

    if (data) {
        [request setHTTPBody:data];
    }

    // Construct URLRequest
    return [request copy];
}
@end
