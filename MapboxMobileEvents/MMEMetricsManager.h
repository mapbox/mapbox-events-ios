#import <Foundation/Foundation.h>
#import "MMEMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@class MMEEvent;
@class MMELogger;
@protocol MMEEventConfigProviding;

typedef void(^OnMetricsError)(NSError* error);
typedef void(^OnMetricsException)(NSException* exception);
typedef BOOL(^IsReachableViaWifi)(void);

/*!
 @brief Event driven interface managing the current state and file loading of SDK metrics
 */
@interface MMEMetricsManager : NSObject

// MARK: - Properties

@property (nonatomic, readonly) MMEMetrics *metrics;
@property (nonatomic, readonly) NSURL *pendingMetricsFileURL;

// MARK: - Initializers

- (instancetype)init NS_UNAVAILABLE;

/*!
 @Brief Initializer
 @param config Differentiated Config
 @param pendingMetricsFileURL File url for creating/archiving events
 */
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
         pendingMetricsFileURL:(NSURL*)pendingMetricsFileURL;

/*!
 @Brief Designated Initializer
 @param config Differentiated Config
 @param pendingMetricsFileURL File url for creating/archiving events
 @param onMetricsError Block called with MMEEvent for Error debug logging
 @param onMetricsException Block called with MMEEvent for Exception debug logging
 @param isReachableViaWifi Block caleld to check if Wifi is reachable
 */
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
         pendingMetricsFileURL:(NSURL*)pendingMetricsFileURL
                onMetricsError:(OnMetricsError)onMetricsError
            onMetricsException:(OnMetricsException)onMetricsException
            isReachableViaWifi:(IsReachableViaWifi)isReachableViaWifi NS_DESIGNATED_INITIALIZER;

// MARK: - Metric Events

/*! @brief Bytes have been sent */
- (void)updateSentBytes:(NSUInteger)bytes;

/*! @brief Bytes have been received */
- (void)updateReceivedBytes:(NSUInteger)bytes;

/*! @brief Events are moving from queue to api calls */
- (void)updateMetricsFromEventQueue:(NSArray<MMEEvent*>*)eventQueue;

// TODO: - This appears to be used for most api call tracking?
// It appears this is looking to evaluate how many element models are lost due to failures
// Perhaps it would make sense to rename something more generic such as elements?

/*!
 @brief Event API call has completed with count
 @discussion Provides mechanism to track the rate of success or failure due to Network/API response or failure to build URLRequest
             Should be called after request event succeeds/fails, or if  the URLRequest fails to build.
 @param eventCount The number of events packaged in the request
 @param request The url Request conveying if the request was created successfuly or not
 @param error The resulting error from the completion
 */
- (void)updateMetricsFromEventCount:(NSUInteger)eventCount
                            request:(nullable NSURLRequest *)request
                              error:(nullable NSError *)error;

- (void)updateConfigurationJSON:(NSDictionary *)configuration;

/*! @brief Most Recent Coordinate has been received */
- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate;

/*! @brief Applicatoin has woken up from CLRegion exit */
- (void)incrementAppWakeUpCount;

/*! @brief Reset Metrics*/
- (void)resetMetrics;

// MARK: - Archived Telemetry Metrics

/*! loads any pending telemetry metrics events from ~/Library/Caches */
- (nullable MMEEvent *)loadPendingTelemetryMetricsEvent;

/*!
 @brief generates an event with the current telemetry metrics
 @discussion if this method returns nil the framework will write the pending telemetry metrics
    to a file in ~/Library/Caches, this event may be loaded with -loadPendingTelemetryMetricsEvent
 @returns nil for pending events, or a telemetry event which is ready to send
*/
- (nullable MMEEvent *)generateTelemetryMetricsEvent;

// MARK: - MMEEvent

- (NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
