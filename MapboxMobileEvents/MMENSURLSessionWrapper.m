#import "MMENSURLSessionWrapper.h"
#import "MMETrustKitWrapper.h"
#import "TrustKit.h"


@interface MMENSURLSessionWrapper ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) dispatch_queue_t serialQueue;

@end

@implementation MMENSURLSessionWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        _serialQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@.events.serial", NSStringFromClass([self class])] UTF8String], DISPATCH_QUEUE_SERIAL);
        [MMETrustKitWrapper configureCertificatePinningValidation];
    }
    return self;
}

#pragma mark MMENSURLSessionWrapper

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    dispatch_async(self.serialQueue, ^{
        __block NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(data, response, error);
            }
            dataTask = nil;
        }];
        [dataTask resume];
    });
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    // Call into TrustKit here to do pinning validation
    if (![[TrustKit sharedInstance].pinningValidator handleChallenge:challenge completionHandler:completionHandler]) {
        // TrustKit did not handle this challenge: perhaps it was not for server trust
        // or the domain was not pinned. Fall back to the default behavior
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
