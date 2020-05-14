#ifndef MMEEventsManager_Private_h
#define MMEEventsManager_Private_h

NS_ASSUME_NONNULL_BEGIN

@class MMEAPIClient;
@class MMECommonEventData;
@class MMEPreferences;
@class MMEUniqueIdentifier;
@class MMEUIApplicationWrapper;
@class MMEMetricsManager;
@class MMEDispatchManager;
@class MMELogger;
@protocol MMEUIApplicationWrapper;

@interface MMEEventsManager (Private)

/*! @Brief Default Initializer */
- (instancetype)initWithDefaults;

/*! @Brief Designated Initializer */
- (instancetype)initWithPreferences:(MMEPreferences*)preferences
                   uniqueIdentifier:(MMEUniqueIdentifier*)uniqueIdentifier
                        application:(id <MMEUIApplicationWrapper>)application
                     metricsManager:(MMEMetricsManager*)metricsManager
                    dispatchManager:(MMEDispatchManager*)dispatchManager
                             logger:(MMELogger*)logger;

- (void)pushEvent:(MMEEvent *)event;

- (void)sendTelemetryMetricsEvent;

- (void)resetEventQueuing;

- (void)pauseOrResumeMetricsCollectionIfRequired;

@end

NS_ASSUME_NONNULL_END

#endif /* MMEEventsManager_Private_h */
