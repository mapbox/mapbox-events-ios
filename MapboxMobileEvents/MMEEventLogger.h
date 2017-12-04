#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MMEEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventLogger : NSObject

@property (nonatomic, getter=isEnabled) BOOL enabled;

+ (instancetype)sharedLogger;

- (void)logEvent:(MMEEvent *)event;
- (void)readAndDisplayLogFileFromDate:(NSDate *)logDate;

@end

NS_ASSUME_NONNULL_END

