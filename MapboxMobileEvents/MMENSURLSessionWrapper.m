#import "MMENSURLSessionWrapper.h"
#import "MMEEventsManager.h"
#import "MMECertPin.h"
#import "MMEEvent.h"
#import "MMELogger.h"

// MARK: -

@interface MMEEventsManager (Private)
- (void)pushEvent:(MMEEvent *)event;
@end

// MARK: -

@interface MMENSURLSessionWrapper ()

/*! Resulting Call Queue*/
@property (nonatomic) dispatch_queue_t serialQueue;

/*! Controller handling the responsibility of Cert Pinning*/
@property (nonatomic) MMECertPin *certPin;

/*! URLSession instance used to make calls*/
@property (nonatomic) NSURLSession *session;

@end

@implementation MMENSURLSessionWrapper

// MARK: - Defaults

+ (dispatch_queue_t)makeDispatchQueue {
    return dispatch_queue_create(
                                 [[NSString stringWithFormat:@"%@.events.serial", NSStringFromClass([self class])] UTF8String], DISPATCH_QUEUE_SERIAL);
}

// MARK: - Lifecycle

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration*)sessionConfiguration
                          eventConfiguration:(id <MMEEventConfigProviding>)eventConfiguration {

    return [self initWithConfiguration:sessionConfiguration
                       completionQueue:[MMENSURLSessionWrapper makeDispatchQueue]
                               certPin:[[MMECertPin alloc] initWithConfig:eventConfiguration]];
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration*)configuration
         completionQueue:(dispatch_queue_t)queue
                 certPin:(MMECertPin*)certPin {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:nil];
        _serialQueue = queue;
        _certPin = certPin;
    }
    return self;
}

-(void)invalidate {
    [self.session invalidateAndCancel];
}

// MARK: MMENSURLSessionWrapper

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

// MARK: NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.certPin handleChallenge:challenge completionHandler:completionHandler];
    });
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    if (error) { // only recreate the session if the error was non-nil
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        [MMELogger.sharedLogger logEvent:[MMEEvent debugEventWithError:error]];
    }
    else { // release the session object
        self.session = nil;
    }
}

@end
