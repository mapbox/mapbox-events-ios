#import "MMEMetricsManagerCallCounter.h"

@interface MMEMetricsManagerCallCounter ()
@property (nonatomic, assign) NSUInteger updateSentBytesCallCount;
@property (nonatomic, assign) NSUInteger updateReceivedBytesCallCount;
@property (nonatomic, assign) NSUInteger updateFromEventQueueCallCount;
@property (nonatomic, assign) NSUInteger updateFromEventCountCallCount;
@property (nonatomic, assign) NSUInteger updateConfigurationJSONCallCount;
@property (nonatomic, assign) NSUInteger updateCoordinateCallCount;
@property (nonatomic, assign) NSUInteger incrementAppWakeUpCallCount;
@property (nonatomic, assign) NSUInteger resetMetricsCallCount;
@property (nonatomic, assign) NSUInteger loadPendingTelemetryMetricsEventCallCount;
@property (nonatomic, assign) NSUInteger generateTelemetrymetricsEventCallCount;

@end

@implementation MMEMetricsManagerCallCounter

- (void)updateSentBytes:(NSUInteger)bytes {
    self.updateSentBytesCallCount += 1;
    [super updateSentBytes:bytes];
}

- (void)updateReceivedBytes:(NSUInteger)bytes {
    self.updateReceivedBytesCallCount += 1;
    [super updateReceivedBytes:bytes];
}

- (void)updateMetricsFromEventQueue:(NSArray<MMEEvent*>*)eventQueue {
    self.updateFromEventQueueCallCount += 1;
    [super updateMetricsFromEventQueue:eventQueue];
}

- (void)updateMetricsFromEventCount:(NSUInteger)eventCount
                            request:(nullable NSURLRequest *)request
                              error:(nullable NSError *)error {
    self.updateFromEventCountCallCount += 1;
    [super updateMetricsFromEventCount:eventCount request:request error:error];

}

- (void)updateConfigurationJSON:(NSDictionary *)configuration {
    self.updateConfigurationJSONCallCount += 1;
    [super updateConfigurationJSON:configuration];
}

- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate {
    self.updateCoordinateCallCount += 1;
    [super updateCoordinate:coordinate];
}

- (void)incrementAppWakeUpCount {
    self.incrementAppWakeUpCallCount += 1;
    [super incrementAppWakeUpCount];
}

- (void)resetMetrics {
    self.resetMetricsCallCount += 1;
    [super resetMetrics];
}

- (nullable MMEEvent *)loadPendingTelemetryMetricsEvent {
    self.loadPendingTelemetryMetricsEventCallCount += 1;
    return [super loadPendingTelemetryMetricsEvent];
}

- (nullable MMEEvent *)generateTelemetryMetricsEvent {
    self.generateTelemetrymetricsEventCallCount += 1;
    return [super generateTelemetryMetricsEvent];
}

@end
