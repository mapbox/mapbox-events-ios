#import <Foundation/Foundation.h>

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventLogger : NSObject

+ (BOOL)isEnabled;
+ (void)setEnabled:(BOOL)enabled;
+ (void)logEvent:(MMEEvent *)event;

@end

NS_ASSUME_NONNULL_END
