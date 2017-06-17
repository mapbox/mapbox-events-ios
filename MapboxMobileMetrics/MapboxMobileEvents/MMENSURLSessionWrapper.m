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

#pragma mark NSURLSessionDelegate

- (BOOL)evaluateCertificateWithCertificateData:(NSData *)certificateData keyCount:(CFIndex)keyCount serverTrust:(SecTrustRef)serverTrust challenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^) (NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    for (int lc = 0; lc < keyCount; lc++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, lc);
        NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
        if ([remoteCertificateData isEqualToData:certificateData]) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            return YES;
        }
    }
    return NO;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^) (NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        SecTrustResultType trustResult;
        
        // Validate the certificate chain with the device's trust store anyway this *might* give use revocation checking
        SecTrustEvaluate(serverTrust, &trustResult);
        
        BOOL found = NO; // For clarity; we start in a state where the challange has not been completed and no certificate has been found
        
        if (trustResult == kSecTrustResultUnspecified) {
            // Look for a pinned certificate in the server's certificate chain
            CFIndex numKeys = SecTrustGetCertificateCount(serverTrust);
            
            // Check certs in the following order: digicert 2016, digicert 2017, geotrust 2016, geotrust 2017
            found = [self evaluateCertificateWithCertificateData:self.digicertCert_2016 keyCount:numKeys serverTrust:serverTrust challenge:challenge completionHandler:completionHandler];
            if (!found) {
                found = [self evaluateCertificateWithCertificateData:self.digicertCert_2017 keyCount:numKeys serverTrust:serverTrust challenge:challenge completionHandler:completionHandler];
            }
            if (!found) {
                found = [self evaluateCertificateWithCertificateData:self.geoTrustCert_2016 keyCount:numKeys serverTrust:serverTrust challenge:challenge completionHandler:completionHandler];
            }
            if (!found) {
                found = [self evaluateCertificateWithCertificateData:self.geoTrustCert_2017 keyCount:numKeys serverTrust:serverTrust challenge:challenge completionHandler:completionHandler];
            }
            
            // If challenge can't be completed with any of the above certs, then try the test server if the app is configured to use the test server
            if (!found && _usesTestServer) {
                found = [self evaluateCertificateWithCertificateData:self.testServerCert keyCount:numKeys serverTrust:serverTrust challenge:challenge completionHandler:completionHandler];
            }
        }
        
        if (!found) {
            // No certificate was found so cancel the connection.
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        }
    }
}

@end
