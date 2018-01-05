#import <Foundation/Foundation.h>

@class MMENSURLSessionWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol MMENSURLSessionWrapper <NSObject>

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end

@interface MMENSURLSessionWrapper : NSObject <MMENSURLSessionWrapper, NSURLSessionDelegate>

@end

NS_ASSUME_NONNULL_END
