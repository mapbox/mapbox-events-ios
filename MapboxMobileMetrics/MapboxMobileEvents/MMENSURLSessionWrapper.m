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

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^) (NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        SecTrustResultType trustResult;
        
        // Validate the certificate chain with the device's trust store anyway
        // This *might* give use revocation checking
        SecTrustEvaluate(serverTrust, &trustResult);
        if (trustResult == kSecTrustResultUnspecified)
        {
            // Look for a pinned certificate in the server's certificate chain
            long numKeys = SecTrustGetCertificateCount(serverTrust);
            
            BOOL found = NO;
            // Try GeoTrust Cert First
            for (int lc = 0; lc < numKeys; lc++) {
                SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, lc);
                NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
                
                // Compare Remote Key With Local Version
                if ([remoteCertificateData isEqualToData:_geoTrustCert]) {
                    // Found the certificate; continue connecting
                    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                    found = YES;
                    break;
                }
            }
            
            if (!found) {
                // Fallback to Digicert Cert
                for (int lc = 0; lc < numKeys; lc++) {
                    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, lc);
                    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
                    
                    // Compare Remote Key With Local Version
                    if ([remoteCertificateData isEqualToData:_digicertCert]) {
                        // Found the certificate; continue connecting
                        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                        found = YES;
                        break;
                    }
                }
                
                if (!found && _usesTestServer) {
                    // See if this is test server
                    for (int lc = 0; lc < numKeys; lc++) {
                        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, lc);
                        NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
                        
                        // Compare Remote Key With Local Version
                        if ([remoteCertificateData isEqualToData:_testServerCert]) {
                            // Found the certificate; continue connecting
                            completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                            found = YES;
                            break;
                        }
                    }
                }
                
                if (!found) {
                    // The certificate wasn't found in GeoTrust nor Digicert. Cancel the connection.
                    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                }
            }
        }
        else
        {
            // Certificate chain validation failed; cancel the connection
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        }
    }
}

@end
