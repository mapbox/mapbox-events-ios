#ifndef MMEEventsManager_Private_h
#define MMEEventsManager_Private_h

NS_ASSUME_NONNULL_BEGIN

@class MMEAPIClient;
@class MMECommonEventData;
@class MMEPreferences;
@class MMEUniqueIdentifier;
@class MMEUIApplicationWrapper;
@class MMEMetricsManager;
@class MMELogger;
@class MMEConfigService;

@protocol MMEUIApplicationWrapper;

@interface MMEEventsManager (Private)

/*! @Brief Default Initializer */
- (instancetype)initWithDefaults;

/*! @Brief Designated Initializer */
- (instancetype)initWithPreferences:(MMEPreferences*)preferences
                   uniqueIdentifier:(MMEUniqueIdentifier*)uniqueIdentifier
                        application:(id <MMEUIApplicationWrapper>)application
                     metricsManager:(MMEMetricsManager*)metricsManager
                             logger:(MMELogger*)logger;

- (void)pushEvent:(MMEEvent *)event;

- (void)sendTelemetryMetricsEvent;

- (void)resetEventQueuing;

- (void)pauseOrResumeMetricsCollectionIfRequired;

/*!
 @Brief Configures a client with expected listener behaviors
 @param client APIClient responsible for making API Calls
 @returns a new client instance configured with expected metrics gathering observations
 */
-(MMEAPIClient*)configureClientListeners:(MMEAPIClient*)client;

/*!
 ConfigService Factory
 @param client APIClient responsible for making API Calls
 @param config Configuration dictating variations in behavior
 @returns Returns a new ConfigurationsService configured to update preferences on load
 */
-(MMEConfigService*)makeConfigServiceWithClient:(MMEAPIClient*)client
                                         config:(id <MMEEventConfigProviding>)config;

@end

NS_ASSUME_NONNULL_END

#endif /* MMEEventsManager_Private_h */
