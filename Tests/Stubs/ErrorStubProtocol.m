#import "ErrorStubProtocol.h"

@implementation ErrorStubProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
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

            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http:test.com"]
                                                                      statusCode:400
                                                                     HTTPVersion:nil
                                                                    headerFields:nil];

            [strongSelf.client URLProtocol:self
                        didReceiveResponse:response
                        cacheStoragePolicy:NSURLCacheStorageNotAllowed];

            [strongSelf.client URLProtocol:self didLoadData:NSData.new];
            [strongSelf.client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"NSURLErrorDomain" code:-999 userInfo:@{}]];
            [strongSelf.client URLProtocolDidFinishLoading:self];
        }
    });
}

- (void)stopLoading {
    // No-Op
}

@end
