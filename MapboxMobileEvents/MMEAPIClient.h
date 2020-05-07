#import <Foundation/Foundation.h>
#import "MMETypes.h"

NS_ASSUME_NONNULL_BEGIN

@class MMEEvent;
@class MMEMetricsManager;
@protocol MMEEventConfigProviding;

/// Asynchronous Interface with API
@interface MMEAPIClient : NSObject

/// Are we currently getting configuration updates?
/// TODO: No need for this state. Client should no need to know this info. Only needs to wrap API calls
@property (nonatomic, readonly) BOOL isGettingConfigUpdates;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                metricsManager:(MMEMetricsManager*)metricsManager;

// MARK: - Events Service

- (void)postEvents:(NSArray <MMEEvent*> *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

// MARK: - Configuration Service

/// Start the Configuration update process
- (void)startGettingConfigUpdates;

/// Stop the Configuration update process
- (void)stopGettingConfigUpdates;

@end

NS_ASSUME_NONNULL_END
