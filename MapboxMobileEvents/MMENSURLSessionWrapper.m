#import "MMENSURLSessionWrapper.h"
//#import "MMETrustKitProvider.h"
#import "MMECertPin.h"


@interface MMENSURLSessionWrapper ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic) MMECertPin *certPin;

@end

@implementation MMENSURLSessionWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        _serialQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@.events.serial", NSStringFromClass([self class])] UTF8String], DISPATCH_QUEUE_SERIAL);
        _certPin = [[MMECertPin alloc]init];
    }
    return self;
}

- (void)reconfigure:(MMEEventsConfiguration *)configuration {
    [self.certPin updateWithConfiguration:configuration];
}

#pragma mark MMENSURLSessionWrapper

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    dispatch_async(self.serialQueue, ^{
        __block NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(data, response, error);
                });
            }
            dataTask = nil;
        }];
        [dataTask resume];
    });
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    __block void (^completion)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable) = nil;
    
    completion = ^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(disposition, credential);
            }
            completion = nil;
        });
    };
    
    // From SecTrustEvaluate docs:
    /*
     This function will completely evaluate trust before returning,
     possibly including network access to fetch intermediate certificates or to
     perform revocation checking. Since this function can block during those
     operations, you should call it from within a function that is placed on a
     dispatch queue, or in a separate thread from your application's main
     run loop. Alternatively, you can use the SecTrustEvaluateAsync function.
     */
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __typeof__(self) strongSelf = weakSelf;
        // Call into TrustKit here to do pinning validation
        [strongSelf.certPin handleChallenge:challenge completionHandler:completionHandler];
    });
}

@end
