#import <Foundation/Foundation.h>

@interface MMEEventsConfiguration : NSObject

@property (nonatomic) NSUInteger eventFlushCountThreshold;
@property (nonatomic) NSUInteger eventFlushSecondsThreshold;

+ (instancetype)defaultEventsConfiguration;

@end
