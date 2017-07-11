#import "MMEEventsConfiguration.h"

@implementation MMEEventsConfiguration

+ (instancetype)defaultEventsConfiguration {
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = 180;
    configuration.eventFlushSecondsThreshold = 180;
    configuration.instanceIdentifierRotationTimeInterval = 24 * 3600; // 24 hours
    return configuration;
}

@end
