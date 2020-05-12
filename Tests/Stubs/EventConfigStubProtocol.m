#import "EventConfigStubProtocol.h"
#import "NSBundle+TestBundle.h"

@implementation EventConfigStubProtocol

/*! @Brief Name used by both response/data files */
static NSString* name = @"events-config";

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // Poor Mans API Equivalency Check
    return [@"/events-config" isEqualToString:request.URL.path];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    // No need to modify request
    return request;
}

- (void)startLoading
{
    __weak __typeof__(self) weakSelf = self;

    // Dispatch of initial thread to follow asynchronous resource loading expectations
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            // Load File
            NSURL* url = [NSBundle.testBundle URLForResource:@"events-config"
                                               withExtension:@"json"];
            NSData* data = [NSData dataWithContentsOfURL:url];

            NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                      statusCode:200
                                                                     HTTPVersion:@"1.1"
                                                                    headerFields:@{
                                                                        @"Content-Type": @"application/json; charset=utf-8",
                                                                    }];


            [strongSelf.client URLProtocol:self
                      didReceiveResponse:response
                      cacheStoragePolicy:NSURLCacheStorageNotAllowed];

            [strongSelf.client URLProtocol:self didLoadData:data];
            [strongSelf.client URLProtocolDidFinishLoading:self];
        }
    });
}

- (void)stopLoading {
    // No-Op
}
@end
