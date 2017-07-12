#import <Foundation/Foundation.h>

@class MMENSURLSessionWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol MMENSURLSessionWrapper <NSObject>

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@property (nonatomic) BOOL usesTestServer;

@end

@interface MMENSURLSessionWrapper : NSObject <MMENSURLSessionWrapper, NSURLSessionDelegate>

@property (nonatomic) BOOL usesTestServer;

@end

NS_ASSUME_NONNULL_END
