#import <Foundation/Foundation.h>

@interface MMEEventsConfiguration : NSObject

@property (nonatomic) NSUInteger eventFlushCountThreshold;

+ (instancetype)defaultEventsConfiguration;

@end
