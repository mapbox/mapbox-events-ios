#import <Foundation/Foundation.h>

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@protocol MMEAPIClient <NSObject>

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;
@property (nonatomic, copy) NSString *hostSDKVersion;
@property (nonatomic, copy, null_resettable) NSURL *baseURL;

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

@end

@interface MMEAPIClient : NSObject<MMEAPIClient>

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;
@property (nonatomic, copy) NSString *hostSDKVersion;
@property (nonatomic, copy, null_resettable) NSURL *baseURL;

- (instancetype)initWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion;

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
