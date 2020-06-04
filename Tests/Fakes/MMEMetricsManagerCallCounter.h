#import "MMEMetricsManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetricsManagerCallCounter : MMEMetricsManager

@property (nonatomic, assign, readonly) NSUInteger updateSentBytesCallCount;
@property (nonatomic, assign, readonly) NSUInteger updateReceivedBytesCallCount;
@property (nonatomic, assign, readonly) NSUInteger updateFromEventQueueCallCount;
@property (nonatomic, assign, readonly) NSUInteger updateFromEventCountCallCount;
@property (nonatomic, assign, readonly) NSUInteger updateConfigurationJSONCallCount;
@property (nonatomic, assign, readonly) NSUInteger updateCoordinateCallCount;
@property (nonatomic, assign, readonly) NSUInteger incrementAppWakeUpCallCount;
@property (nonatomic, assign, readonly) NSUInteger resetMetricsCallCount;
@property (nonatomic, assign, readonly) NSUInteger loadPendingTelemetryMetricsEventCallCount;
@property (nonatomic, assign, readonly) NSUInteger generateTelemetrymetricsEventCallCount;

@end

NS_ASSUME_NONNULL_END
