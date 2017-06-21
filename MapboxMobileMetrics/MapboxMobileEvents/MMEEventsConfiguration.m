#import "MMEEventsConfiguration.h"

@implementation MMEEventsConfiguration

+ (instancetype)defaultEventsConfiguration {
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = 180;
    configuration.eventFlushSecondsThreshold = 5;
    return configuration;
}

@end
