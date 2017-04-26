#import "MMETestStub.h"
#import "MMENSURLSessionWrapper.h"

@interface MMENSURLSessionWrapperFake : MMETestStub <MMENSURLSessionWrapper>

@property (nonatomic, nullable) NSURLRequest *request;
@property (nonatomic, nullable) void (^callingCompletionHandler)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);

- (void)completeProcessingWithData:(NSData * _Nullable)data response:(NSURLResponse * _Nullable)response error:(NSError * _Nullable)error;

@end
