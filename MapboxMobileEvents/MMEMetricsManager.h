#import <Foundation/Foundation.h>
#import "MMEMetrics.h"
#import "MMEEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetricsManager : NSObject

@property (nonatomic, readonly) MMEMetrics *metrics;

+ (instancetype)sharedManager;

- (void)updateSentBytes:(NSUInteger)bytes;
- (void)updateReceivedBytes:(NSUInteger)bytes;
- (void)updateMetricsFromEventQueue:(NSArray *)eventQueue;
- (void)updateMetricsFromEventCount:(NSUInteger)eventCount request:(nullable NSURLRequest *)request error:(nullable NSError *)error;
- (void)updateConfigurationJSON:(NSDictionary *)configuration;
- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)incrementAppWakeUpCount;
- (void)resetMetrics;

- (MMEEvent *)generateTelemetryMetricsEvent;

- (NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
