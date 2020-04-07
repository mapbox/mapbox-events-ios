#ifndef MMEAPIClient_Private_h
#define MMEAPIClient_Private_h

NS_ASSUME_NONNULL_BEGIN

@class MMEEvent;

@protocol MMEAPIClient <NSObject> // MME_DEPRECATED

- (void)postEvents:(NSArray *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END

#endif /* MMEAPIClient_Private_h */
