#import "MMENSURLSessionWrapper.h"

@interface MMENSURLSessionWrapper ()

@property (nonatomic) NSURLSession *session;

@end

@implementation MMENSURLSessionWrapper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark NSURLSessionDelegate

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    __block NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(data, response, error);
        }
        dataTask = nil;
    }];
    [dataTask resume];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^) (NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
    SecTrustResultType trustResult = 0;

    // Validate the certificate chain with the device's trust store anyway -- this *might* give use revocation checking
    SecTrustEvaluate(serverTrust, &trustResult);

    if (trustResult == kSecTrustResultUnspecified) {

        NSLog(@"================> unspecified");

    }
}

@end
