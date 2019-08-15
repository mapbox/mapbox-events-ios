#import <Foundation/Foundation.h>
#import "MMETypes.h"

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventLogger : NSObject

@property (nonatomic, getter=isEnabled) BOOL enabled;

+ (instancetype)sharedLogger;

- (void)logEvent:(MMEEvent *)event;
- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes;

#if HTML_GENERATION
- (void)readAndDisplayLogFileFromDate:(NSDate *)logDate;
#endif

@end

NS_ASSUME_NONNULL_END

