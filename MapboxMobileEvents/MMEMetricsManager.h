#import <Foundation/Foundation.h>
#import "MMEMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetricsManager : NSObject

@property (nonatomic, readonly) MMEMetrics *metrics;

+ (instancetype)sharedManager;

- (void)metricsFromData:(NSData *)data;
- (void)metricsFromEventQueue:(NSArray *)eventQueue;
- (void)metricsFromEvents:(nullable NSArray *)events error:(nullable NSError *)error;
- (void)captureConfigurationJSON:(NSDictionary *)configuration;
- (void)captureCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)incrementAppWakeUpCount;
- (void)updateDateUTC;
- (void)resetMetrics;

- (NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
