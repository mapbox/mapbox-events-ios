#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MMETypes.h"

typedef NS_ENUM(NSUInteger, MMELoglevel) {
    MMELogFatal,
    MMELogError,
    MMELogWarn,
    MMELogInfo,
    MMELogDebug,
    MMELogEvent
};

#if DEBUG
#define MMELOG(priority, type, message) [MMEEventLogger.sharedLogger logPriority:priority withType:type andMessage:message];
#else
#define MMELOG(priority, type, message) ((void)0)
#endif

#pragma mark -

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventLogger : NSObject

/*! @brief Allows debugging events to be logged and/or printed out to the console.
*/
@property (nonatomic, getter=isEnabled) BOOL enabled;

/*! @brief Returns the shared logging object.
*/
+ (instancetype)sharedLogger;

/*! @brief A method used to log a single debug event for debugging purposes(when debugging is enabled).
    @param event event used to log information useful to debugging
*/
- (void)logEvent:(MMEEvent *)event;

/*! @brief A method used to log debug information based on priority(when debugging is enabled).
    @param priority priority of the error being logged (MMELogLevel enum)
    @param type type of debug event being logged
    @param message used to log information useful to debugging
*/
- (void)logPriority:(NSUInteger)priority withType:(NSString *)type andMessage:(NSString *)message;

/*! @brief A method used to construct a debug event and log all at once.
    @param attributes attributes belonging to an MMEEvent
*/
- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes; MME_DEPRECATED

/*! @brief A block to be called when debug logging is enabled.
    @param priority priority of the error being logged (MMELogLevel enum)
    @param type type of debug event being logged
    @param message used to log information useful to debugging
*/
typedef void (^MMELoggingBlockHandler)(NSUInteger priority, NSString *type, NSString *message);

/*! @brief The handler this SDK uses to log messages. If this property is set to nil or if no custom handler is provided this property is set to the default handler. The default handler uses `NSLog`.
*/
@property (nonatomic, copy, null_resettable) MMELoggingBlockHandler handler;

@end

NS_ASSUME_NONNULL_END
