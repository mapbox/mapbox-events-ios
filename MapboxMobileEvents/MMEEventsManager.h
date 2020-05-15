#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MMETypes.h"

NS_ASSUME_NONNULL_BEGIN

@class MMEEvent;
@class MMEAPIClient;
@class MMEPreferences;
@protocol MMEAPIClient;
@protocol MMEEventConfigProviding;
@protocol MMEEventsManagerDelegate;

/** Mapbox Mobile Events Manager
 
 `MMEEventsManager` manages sending telemetry events for Mapbox frameworks.
 
 ## Theory of Operation
 
 The events manager maintains a queue of pending events, groups them according to configurable rules,
 serializes and compresses the data then posts it to the Mapbox events service.
 
 ## Delegate Interface
 
 The events manager provides a delegate interface for monitoring it's activity `MMEEventsManagerDelegate`
 
*/
@interface MMEEventsManager : NSObject

// MARK: - Properties

/// events manager delegate
@property (nonatomic, weak) id<MMEEventsManagerDelegate> delegate;
/// Active SKU Identifier to add to events
@property (nonatomic, copy) NSString *skuId;

/// Configuration EventsManager is running in
@property (nonatomic, readonly) MMEPreferences* configuration;

// MARK: -

- (instancetype)init NS_UNAVAILABLE;

/// Shared Mapbox Mobile Events Manager
+ (instancetype)sharedManager;


// MARK: - Events Manager Lifecycle

/// Start the events manager
/// - Parameter accessToken: Mapbox Access Token
/// - Throws: no exceptions
- (void)startEventsManagerWithToken:(NSString *)accessToken;

/// To be deprecated when User Agent Reform is Achieved
- (void)startEventsManagerWithToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion;

/// Attempts to send all pending events immediately
/// - Throws: no exceptions
- (void)flushEventsManager;

/// Flush the event queue and stop accepting new events
/// - Throws: no exceptions
- (void)stopEventsManager;

// MARK: - Post Events or Files

/// Send a turnstile event for the accessToken, if necessary
/// - Throws: no exceptions
- (void)sendTurnstileEvent;

/// Enqueue an event
///   - Parameter event: added too the event queue
- (void)enqueueEvent:(MMEEvent *)event;

/// Post files with metadata
/// - Parameter metadata: array of metadata tags
/// - Parameter filePaths: array of local files to upload
/// - Parameter completionHandler: if provided, block will be run when the post completes
- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

// MARK: - Error & Exception Reporting

/// report an error to the telemetry service
/// - Returns: the report event, for inspection or logging
/// - Throws: no exceptions
- (MMEEvent *)reportError:(NSError *)eventsError;

/// report an exception to the telemetry service
/// - Returns: the report event, for inspection or logging
/// - Throws: no exceptions
- (MMEEvent *)reportException:(NSException *)eventException;

// MARK: - Debug Handler

/** Sets the handler for debug logging in MMELogger. If this property is set to nil or if no custom handler is provided this property is set to the default handler.
    -Parameter: handler The handler this SDK uses to log messages.
*/
- (void)setDebugHandler:(void (^)(NSUInteger, NSString *, NSString *))handler;

#pragma mark - Deprecated API

@property (nonatomic, nullable) id<MMEAPIClient> apiClient MME_DEPRECATED;

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion
    MME_DEPRECATED_GOTO("use startEventsManagerWithToken:", "-startEventsManagerWithToken:");
- (void)flush MME_DEPRECATED_GOTO("use flushEventsManager", "-flushEventsManager");
- (void)enqueueEventWithName:(NSString *)name MME_DEPRECATED_GOTO("use enqueueEvent:", "-enqueueEvent:");
- (void)enqueueEventWithName:(NSString *)name attributes:(MMEMapboxEventAttributes *)attributes
    MME_DEPRECATED_GOTO("use enqueueEvent:", "-enqueueEvent:");
- (void)disableLocationMetrics MME_DEPRECATED;

@end

// MARK: -

/// Events Manager Delegate
@protocol MMEEventsManagerDelegate <NSObject>

@optional

/** eventsManager:didUpdateLocations: reports location updates to the delegate
    @param eventsManager shared manager
    @param locations array of CLLocations
*/
- (void)eventsManager:(MMEEventsManager *)eventsManager didUpdateLocations:(NSArray<CLLocation *> *)locations;


/** reports errors encountered by the Events Manager to the delegate
    @param eventsManager the shared events manager
    @param error the encountered NSError object
*/
- (void)eventsManager:(MMEEventsManager *)eventsManager didEncounterError:(NSError *)error;

/** reports to the delegate when an event is added to the queue
    @param eventsManager the shared events manager
    @param enqueued the event that will be sent when the queue is flushed
*/
- (void)eventsManager:(MMEEventsManager *)eventsManager didEnqueueEvent:(MMEEvent *)enqueued;

/** reports to the delegate when events are successfully sent
    @param eventsManager the shared events manager
    @param events an array of events which were sent to the events service
*/
- (void)eventsManager:(MMEEventsManager *)eventsManager didSendEvents:(NSArray<MMEEvent *>*)events;


#if TARGET_OS_IOS
/** eventsManager:didVisit: reports visits to the delegate
    @param eventsManager shared manager
    @param visit CLVisit
*/
- (void)eventsManager:(MMEEventsManager *)eventsManager didVisit:(CLVisit *)visit;
#endif

@end

NS_ASSUME_NONNULL_END
