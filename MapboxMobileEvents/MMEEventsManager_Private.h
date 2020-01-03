#ifndef MMEEventsManager_Private_h
#define MMEEventsManager_Private_h

NS_ASSUME_NONNULL_BEGIN

@class MMEAPIClient;
@class MMECommonEventData;

@interface MMEEventsManager (Private)

- (void)pushEvent:(MMEEvent *)event;

- (void)sendTelemetryMetricsEvent;

- (void)resetEventQueuing;

- (void)pauseOrResumeMetricsCollectionIfRequired;

@end

NS_ASSUME_NONNULL_END

#endif /* MMEEventsManager_Private_h */
