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
                              // Geotrust, 2016, SHA1 Fingerprint=1A:62:1C:B8:1F:05:DD:02:A9:24:77:94:6C:B4:1B:53:BF:1D:73:6C
                              @"BhynraKizavqoC5U26qgYuxLZst6pCu9J5stfL6RSYY=",
                              // Geotrust, 2017, SHA1 Fingerprint=20:CE:AB:72:3C:51:08:B2:8A:AA:AB:B9:EE:9A:9B:E8:FD:C5:7C:F6
                              @"yJLOJQLNTPNSOh3Btyg9UA1icIoZZssWzG0UmVEJFfA=",
                              ]
                      }}};
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
