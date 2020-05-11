#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MMECertPin;

@protocol MMENSURLSessionWrapper <NSObject>

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@optional

/*! @biref invalidate the session and release it's internal NSURLSession */
- (void)invalidate;

@end

@interface MMENSURLSessionWrapper : NSObject <MMENSURLSessionWrapper, NSURLSessionDelegate>

/*! @Brief Initializes Default instance*/
- (instancetype)init;

/*! @Brief Initializes instance with configuration */
- (instancetype)initWithConfiguration:(NSURLSessionConfiguration*)configuration;

/*! @Brief Designated Initializer */
- (instancetype)initWithConfiguration:(NSURLSessionConfiguration*)configuration
                      completionQueue:(dispatch_queue_t)queue
                              certPin:(MMECertPin*)certPin;

@end

NS_ASSUME_NONNULL_END
