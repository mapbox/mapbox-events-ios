#import "MMENSURLSessionWrapper.h"
#import <TrustKit/TrustKit.h>

@interface MMENSURLSessionWrapper ()

@property (nonatomic) NSURLSession *session;

@end

@implementation MMENSURLSessionWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        [self configureCertificatePinningValidation];
    }
    return self;
}

- (void)configureCertificatePinningValidation {
    
    // Override TrustKit's logger method
    void (^loggerBlock)(NSString *) = ^void(NSString *message)
    {
        NSLog(@"TrustKit log: %@", message);
        
    };
    [TrustKit setLoggerBlock:loggerBlock];
    
    NSDictionary *trustKitConfig =
    @{
      kTSKSwizzleNetworkDelegates: @NO,
      kTSKPinnedDomains: @{
              @"events.mapbox.com" : @{
                      kTSKEnforcePinning:@YES,
                      kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
                      kTSKPublicKeyHashes : @[
                              /* Production */
                              // Digicert, 2016, SHA1 Fingerprint=0A:80:27:6E:1C:A6:5D:ED:1D:C2:24:E7:7D:0C:A7:24:0B:51:C8:54
                              @"Tb0uHZ/KQjWh8N9+CZFLc4zx36LONQ55l6laDi1qtT4=",
                              // Digicert, 2017, SHA1 Fingerprint=E2:8E:94:45:E0:B7:2F:28:62:D3:82:70:1F:C9:62:17:F2:9D:78:68
                              @"yGp2XoimPmIK24X3bNV1IaK+HqvbGEgqar5nauDdC5E=",
                              // Geotrust, 2016, SHA1 Fingerprint=1A:62:1C:B8:1F:05:DD:02:A9:24:77:94:6C:B4:1B:53:BF:1D:73:6C
                              @"BhynraKizavqoC5U26qgYuxLZst6pCu9J5stfL6RSYY=",
                              // Geotrust, 2017, SHA1 Fingerprint=20:CE:AB:72:3C:51:08:B2:8A:AA:AB:B9:EE:9A:9B:E8:FD:C5:7C:F6
                              @"yJLOJQLNTPNSOh3Btyg9UA1icIoZZssWzG0UmVEJFfA=",
                              ]
                      },
              @"*.tilestream.net" : @{
                      kTSKEnforcePinning:@YES,
                      kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
                      kTSKPublicKeyHashes : @[
                              /* Staging */
                              // Digicert, SHA1 Fingerprint=C6:1B:FE:8C:59:8F:29:F0:36:2E:88:BB:A2:CD:08:3B:F6:59:08:22
                              @"3euxrJOrEZI15R4104UsiAkDqe007EPyZ6eTL/XxdAY=",
                              // Stub: TrustKit requires 2 hashes for every endpoint
                              @"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                              ]
                      }
              }
      };
    [TrustKit initializeWithConfiguration:trustKitConfig];
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

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    // Call into TrustKit here to do pinning validation
    if (![TSKPinningValidator handleChallenge:challenge completionHandler:completionHandler]) {
        // TrustKit did not handle this challenge: perhaps it was not for server trust
        // or the domain was not pinned. Fall back to the default behavior
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
