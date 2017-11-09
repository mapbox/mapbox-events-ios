#import <Foundation/Foundation.h>

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventLogger : NSObject

@property (nonatomic, getter=isEnabled) BOOL enabled;

+ (instancetype)sharedLogger;

- (void)logEvent:(MMEEvent *)event;

@end

NS_ASSUME_NONNULL_END
