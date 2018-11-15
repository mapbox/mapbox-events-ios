#pragma mark - debug protocol to mock up data...

#import "APIServiceURLProtocol.h"

@implementation APIServiceURLProtocol

- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)useCredential:(NSURLCredential *)credential forAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

+ (void)load {
    [NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

- (void)startLoading {

    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"someHost" port:0 protocol:nil realm:nil authenticationMethod:nil];
    NSURLAuthenticationChallenge *challenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace  proposedCredential:nil previousFailureCount:0 failureResponse:nil error:nil sender:self];
    
    [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
    
    NSDictionary *responseDictionary = @{@"status" : @"success"};
    NSError *error = nil;
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseDictionary
                                                           options:0
                                                             error:&error];

    [self.client URLProtocol:self didLoadData:responseData];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if( error ) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}
@end
