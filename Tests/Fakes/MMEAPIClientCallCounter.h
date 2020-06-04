#import "MMEAPIClient.h"
#import "MMEAPIClient_Private.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @Brief Fallthrough Client Proxy which counts calls to public interfaces
*/
@interface MMEAPIClientCallCounter : MMEAPIClient <MMEAPIClient>

/*! Number of times postEvents was called */
@property (nonatomic, assign, readonly) NSUInteger postEventsCount;

/*! Number of times getConfiguration was called */
@property (nonatomic, assign, readonly) NSUInteger getConfigurationCount;

/*! Number of times postMetadata was called */
@property (nonatomic, assign, readonly) NSUInteger postMetadataCount;

/*! Number of times performRequest was called (General API request count) */
@property (nonatomic, assign, readonly) NSUInteger performRequestCount;

/*! Number of times registerOnSerializationError was called */
@property (nonatomic, assign, readonly) NSUInteger registerOnSerializationErrorListenerCount;

/*! Number of times registerOnURLResponse was called */
@property (nonatomic, assign, readonly) NSUInteger registerOnURLResponseCount;

/*! Number of times registerOnEventQueueUpdate was called */
@property (nonatomic, assign, readonly) NSUInteger registerOnEventQueueUpdateCount;

/*! Number of times registeregisterOnEventCountUpdate was called */
@property (nonatomic, assign, readonly) NSUInteger registerOnEventCountUpdateCount;

/*! Number of times registerOnGenerateTelemetryEvent was called */
@property (nonatomic, assign, readonly) NSUInteger registerOnGenerateTelemetryEventCount;

@end
NS_ASSUME_NONNULL_END
