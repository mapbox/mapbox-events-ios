#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MMETypes.h"

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

/*! @brief A method used to construct a debug event and log all at once.
    @param attributes attributes belonging to an MMEEvent
*/
- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes;

/*! @brief A block to be called when debug logging is enabled.
    @param debugEvent event used to log information useful to debugging
*/
typedef void (^MMELoggingBlockHandler)(MMEEvent *debugEvent);

/*! @brief The handler this SDK uses to log messages. If this property is set to nil or if no custom handler is provided this property is set to the default handler. The default handler uses `NSLog`.
*/
@property (nonatomic, copy, null_resettable) MMELoggingBlockHandler handler;

@end

NS_ASSUME_NONNULL_END

