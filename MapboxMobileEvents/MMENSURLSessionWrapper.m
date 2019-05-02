#import "MMENSURLSessionWrapper.h"
#import "MMECertPin.h"


@interface MMENSURLSessionWrapper ()

@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic) MMECertPin *certPin;

@end

@implementation MMENSURLSessionWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
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
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    
    dispatch_async(self.serialQueue, ^{
        __block NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(data, response, error);
                });
            }
            dataTask = nil;
        }];
        [dataTask resume];
        [session finishTasksAndInvalidate];
    });
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.certPin handleChallenge:challenge completionHandler:completionHandler];
    });
}

@end
