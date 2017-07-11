#import "MMETestStub.h"
#import "MMEAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEAPIClientFake : MMETestStub <MMEAPIClient>

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;
@property (nonatomic, copy) NSString *hostSDKVersion;

@property (nonatomic, nullable) void (^callingCompletionHandler)(NSError * _Nullable error);

- (void)completePostingEventsWithError:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
