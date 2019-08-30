#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@protocol MMEAPIClient <NSObject>

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;
@property (nonatomic, copy) NSString *hostSDKVersion;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy, null_resettable) NSURL *baseURL;

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

@optional

- (void)getConfigurationWithCompletionHandler:(nullable void (^)(NSError * _Nullable error, NSData * _Nullable data))completionHandler;
- (void)reconfigure:(MMEEventsConfiguration *)configuration;
- (nullable NSError *)statusErrorFromRequest:(NSURLRequest *)request andHTTPResponse:(NSHTTPURLResponse *)httpResponse;
- (NSError *)unexpectedResponseErrorfromRequest:(NSURLRequest *)request andResponse:(NSURLResponse *)response;

@end

#pragma mark -

@interface MMEAPIClient : NSObject<MMEAPIClient>

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userAgentBase;
@property (nonatomic, copy) NSString *hostSDKVersion;
@property (nonatomic, copy, null_resettable) NSURL *baseURL;

- (instancetype)initWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion;

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)getConfigurationWithCompletionHandler:(nullable void (^)(NSError * _Nullable error, NSData * _Nullable data))completionHandler;
- (nullable NSError *)statusErrorFromRequest:(NSURLRequest *)request andHTTPResponse:(NSHTTPURLResponse *)httpResponse;
- (NSError *)unexpectedResponseErrorfromRequest:(NSURLRequest *)request andResponse:(NSURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
