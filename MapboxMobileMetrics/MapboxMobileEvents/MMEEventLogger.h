#import <Foundation/Foundation.h>

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventLogger : NSObject

@property (class, nonatomic, getter=isEnabled) BOOL enabled;

+ (void)logEvent:(MMEEvent *)event;

@end

NS_ASSUME_NONNULL_END
