#import <Foundation/Foundation.h>
#import "MMETypes.h"

NS_ASSUME_NONNULL_BEGIN

@class MMEEvent;
@protocol MMEEventConfigProviding;

typedef void(^OnErrorBlock)(NSError *error);
typedef void(^OnBytesReceived)(NSUInteger bytes);
typedef void(^OnEventQueueUpdate)(NSArray * eventQueue);
typedef void(^OnEventCountUpdate)(NSUInteger eventCount, NSURLRequest* _Nullable request, NSError * _Nullable error);
typedef void(^OnGenerateTelemetryEvent)(void);
typedef void(^OnLogEvent)(MMEEvent* event);

/// Asynchronous Interface with API
@interface MMEAPIClient : NSObject

@property (nonatomic, readonly) BOOL isGettingConfigUpdates;


- (instancetype)init NS_UNAVAILABLE;


/** Designated Initializer
 @param config Provider of Shared Client Model Information
 @param onError Called on the instance of an error for an API calls
 @param onBytesReceived Called on bytes received an API calls
 @param onEventQueueUpdate Called on the EventQueue updates
 @param onEventCountUpdate Called on the EventCount Udpates
 @param onGenerateTelemetryEvent Called on the Generation of Telemetry Events
 @param onLogEvent Called Upon Event Logging
 */
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                       onError: (OnErrorBlock)onError
               onBytesReceived: (OnBytesReceived)onBytesReceived
            onEventQueueUpdate: (OnEventQueueUpdate)onEventQueueUpdate
            onEventCountUpdate: (OnEventCountUpdate)onEventCountUpdate
      onGenerateTelemetryEvent: (OnGenerateTelemetryEvent)onGenerateTelemetryEvent
                    onLogEvent: (OnLogEvent)onLogEvent;

// MARK: - Events Service

- (void)postEvents:(NSArray <MMEEvent*> *)events completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postEvent:(MMEEvent *)event completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;
- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler;

// MARK: - Configuration Service

/// Start the Configuration update process
- (void)startGettingConfigUpdates;

/// Stop the Configuration update process
- (void)stopGettingConfigUpdates;

@end

NS_ASSUME_NONNULL_END
