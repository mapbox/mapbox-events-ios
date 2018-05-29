#import "MMEEventsConfiguration.h"

static const CLLocationDistance kHibernationRadiusDefault = 300.0;
static const CLLocationDistance kHibernationRadiusWide = 1200.0;
static const NSUInteger kEventFlushCountThresholdDefault = 180;
static const NSUInteger kEventFlushSecondsThresholdDefault = 180;
static const NSTimeInterval kInstanceIdentifierRotationTimeIntervalDefault = 24 * 3600; // 24 hours

@implementation MMEEventsConfiguration

+ (instancetype)defaultEventsConfiguration {
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = kEventFlushCountThresholdDefault;
    configuration.eventFlushSecondsThreshold = kEventFlushSecondsThresholdDefault;
    configuration.instanceIdentifierRotationTimeInterval = kInstanceIdentifierRotationTimeIntervalDefault;
    configuration.locationManagerHibernationRadius = kHibernationRadiusDefault;
    return configuration;
}

+ (instancetype)eventsConfigurationWithVariableRadius:(CLLocationDistance)radius {
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = kEventFlushCountThresholdDefault;
    configuration.eventFlushSecondsThreshold = kEventFlushSecondsThresholdDefault;
    configuration.instanceIdentifierRotationTimeInterval = kInstanceIdentifierRotationTimeIntervalDefault;
    
    if (radius == 0) radius = kHibernationRadiusWide / 2; //return a median radius if no variable radius is set
    else if (radius < kHibernationRadiusDefault) radius = kHibernationRadiusDefault;
    else if (radius > kHibernationRadiusWide) radius = kHibernationRadiusWide;
    
    configuration.locationManagerHibernationRadius = radius;
    return configuration;
}

@end
