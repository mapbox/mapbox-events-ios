#import <Foundation/Foundation.h>
#import "MMEMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@class MMEEvent;
@class MMELogger;
@protocol MMEEventConfigProviding;

typedef void(^OnMetricsError)(NSError* error);
typedef void(^OnMetricsException)(NSException* exception);

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
 */
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
         pendingMetricsFileURL:(NSURL*)pendingMetricsFileURL
                onMetricsError:(OnMetricsError)onMetricsError
            onMetricsException:(OnMetricsException)onMetricsException NS_DESIGNATED_INITIALIZER;

// MARK: - Metrics

- (void)updateSentBytes:(NSUInteger)bytes;
- (void)updateReceivedBytes:(NSUInteger)bytes;
- (void)updateMetricsFromEventQueue:(NSArray *)eventQueue;
- (void)updateMetricsFromEventCount:(NSUInteger)eventCount request:(nullable NSURLRequest *)request error:(nullable NSError *)error;
- (void)updateConfigurationJSON:(NSDictionary *)configuration;
- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)incrementAppWakeUpCount;
- (void)resetMetrics;

// MARK: - Archived Telemetry Metrics

/** loads any pending telemetry metrics events from ~/Library/Caches */
- (MMEEvent *)loadPendingTelemetryMetricsEvent;

/**
 @brief generates an event with the current telemetry metrics
 @returns nil for pending events, or a telemetry event which is ready to send
 @discussion if this method returns nil the framework will write the pending telemetry metrics
    to a file in ~/Library/Caches, this event may be loaded with -loadPendingTelemetryMetricsEvent */
- (MMEEvent *)generateTelemetryMetricsEvent;

// MARK: - MMEEvent

- (NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
