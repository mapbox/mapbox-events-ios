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

/*! Configure Event Manger to monitor for passive data gathering */
- (void)setupPassiveDataCollection;

- (void)pushEvent:(MMEEvent *)event;

/*!
 @Brief Deprecated Event Pushing Support
 @Discussion Provides a mapping based on an event name to some particular structures.
 No longer suggested for use as it doesn't scale and is prone to developer error/typo
 @param name Event Name
 @param attributes Event Attributes
 */
- (void)createAndPushEventBasedOnName:(NSString *)name attributes:(NSDictionary *)attributes;

- (void)sendTelemetryMetricsEvent;

- (void)resetEventQueuing;

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



// MARK: - API COmpletion Handlers

/*!
 @Brief Send Turnstile Event Completion Handler
 @param error API Error Response
 */
-(void)sendTurnstileEventCompletionHandler:(NSError* _Nullable)error;

/*!
 @Brief Post Events Completion handler
 @param events Array of Events posted
 @param error Optional error provided on the status of the request
 */
-(void)postEventsCompletionHandler:(NSArray *)events
                             error:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

#endif /* MMEEventsManager_Private_h */
