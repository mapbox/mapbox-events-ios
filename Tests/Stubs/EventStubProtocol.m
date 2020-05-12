#import "EventStubProtocol.h"

@implementation EventStubProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // API Equivalency Check
    return [@"/events/v2" isEqualToString:request.URL.path];
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
            // Event Reporting is an empty 201 acknowledgement
            NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                      statusCode:201
                                                                     HTTPVersion:@"1.1"
                                                                    headerFields:nil];


            [strongSelf.client URLProtocol:self
                      didReceiveResponse:response
                      cacheStoragePolicy:NSURLCacheStorageNotAllowed];

            [strongSelf.client URLProtocol:self didLoadData:[NSData new]];
            [strongSelf.client URLProtocolDidFinishLoading:self];
        }
    });
}

- (void)stopLoading {
    // No-Op
}

@end
