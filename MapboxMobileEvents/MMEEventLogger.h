#import "MMETypes.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG
#define MMELog(priority, type, message) [MMEEventLogger.sharedLogger logPriority:priority withType:type andMessage:message];
#else
#define MMELog(priority, type, message) ((void)0)
#endif

/// Log Levels for Runtime Filtering
typedef NS_ENUM(NSUInteger, MMELoglevel) {
    MMELogFatal,
    MMELogError,
    MMELogWarn,
    MMELogInfo,
    MMELogDebug,
    MMELogEvent
};

// Mark: -

/** A block to be called when debug logging is enabled.
    - Parameter: priority priority of the error being logged (MMELogLevel enum)
    - Parameter: type type of debug event being logged
    - Parameter: message used to log information useful to debugging
*/
typedef void (^MMELoggingBlockHandler)(NSUInteger priority, NSString *type, NSString *message);

@class MMEEvent;

// MARK: -

/// Event Logging Service
@interface MMEEventLogger : NSObject

///  Allows debugging events to be logged and/or printed out to the console.
@property (nonatomic, getter=isEnabled) BOOL enabled;

/// The handler this SDK uses to log messages. If this property is set to nil or if no custom handler is provided this property is set to the default handler. The default handler uses `NSLog`.
@property (nonatomic, copy, null_resettable) MMELoggingBlockHandler handler;

// MARK: -

///  Returns the shared logging object.
+ (instancetype)sharedLogger;

// MARK: -

/** A method used to log a single debug event for debugging purposes(when debugging is enabled).
    - Parameter: event used to log information useful to debugging */
- (void)logEvent:(MMEEvent *)event;

/** A method used to log debug information based on priority(when debugging is enabled).
    - Paramteer: priority priority of the error being logged (MMELogLevel enum)
    - Parameter: type type of debug event being logged
    - Parameter: message used to log information useful to debugging
*/
- (void)logPriority:(NSUInteger)priority withType:(NSString *)type andMessage:(NSString *)message;

/** A method used to construct a debug event and log all at once.
    - Parameter: attributes attributes belonging to an MMEEvent
*/
- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes MME_DEPRECATED;

@end

NS_ASSUME_NONNULL_END
