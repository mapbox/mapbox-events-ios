#import <Foundation/Foundation.h>
#import "MMEMetrics.h"
#import "MMEEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetricsManager : NSObject

@property (nonatomic, readonly) MMEMetrics *metrics;

+ (instancetype)sharedManager;

- (void)updateMetricsFromData:(NSData *)data;
- (void)updateMetricsFromEventQueue:(NSArray *)eventQueue;
- (void)updateMetricsFromEvents:(nullable NSArray *)events request:(NSURLRequest *)request error:(nullable NSError *)error;
- (void)updateConfigurationJSON:(NSDictionary *)configuration;
- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)incrementAppWakeUpCount;
- (void)resetMetrics;

- (MMEEvent *)generateTelemetryMetricsEvent;

- (NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
