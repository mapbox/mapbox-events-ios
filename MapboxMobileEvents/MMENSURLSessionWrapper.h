#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MMECertPin;
@protocol MMEConfigurationProviding;

@protocol MMENSURLSessionWrapper <NSObject>

- (void)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@optional

/*! @biref invalidate the session and release it's internal NSURLSession */
- (void)invalidate;

@end

@interface MMENSURLSessionWrapper : NSObject <MMENSURLSessionWrapper, NSURLSessionDelegate>

- (instancetype)init NS_UNAVAILABLE;

/*! @Brief Initializes instance with configuration */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration*)sessionConfiguration
                          eventConfiguration:(id <MMEConfigurationProviding>)eventConfiguration;

/*! @Brief Designated Initializer */
- (instancetype)initWithConfiguration:(NSURLSessionConfiguration*)configuration
                      completionQueue:(dispatch_queue_t)queue
                              certPin:(MMECertPin*)certPin NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
