#import <Foundation/Foundation.h>

@interface MMEEventsConfiguration : NSObject

@property (nonatomic) NSUInteger eventFlushCountThreshold;
@property (nonatomic) NSUInteger eventFlushSecondsThreshold;
@property (nonatomic) NSTimeInterval instanceIdentifierRotationTimeInterval;

+ (instancetype)defaultEventsConfiguration;

@end
