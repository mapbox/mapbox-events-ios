#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MMENSURLSessionWrapper <NSObject>

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@optional

- (void)reconfigure:(MMEEventsConfiguration *)configuration;

/*! @biref invalidate the session and release it's internal NSURLSession */
- (void)invalidate;

@end

@interface MMENSURLSessionWrapper : NSObject <MMENSURLSessionWrapper, NSURLSessionDelegate>

@end

NS_ASSUME_NONNULL_END
