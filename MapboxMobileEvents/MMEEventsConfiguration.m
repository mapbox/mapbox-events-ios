#import "MMEEventsConfiguration.h"

static NSString *const kMMEEventsProfile = @"MMEEventsProfile";
static NSString *const kMMERadiusSize = @"MMECustomGeofenceRadius";
static NSString *const kMMEStartupDelay = @"MMEStartupDelay";
static NSString *const kMMECustomProfile = @"Custom";

static const CLLocationDistance kHibernationRadiusDefault = 300.0;
static const CLLocationDistance kHibernationRadiusWide = 1200.0;
static const NSUInteger kEventFlushCountThresholdDefault = 180;
static const NSUInteger kEventFlushSecondsThresholdDefault = 180;
static const NSTimeInterval kInstanceIdentifierRotationTimeIntervalDefault = 24 * 3600;
static const NSTimeInterval kConfigurationRotationTimeIntervalDefault = 24 * 3600; // 24 hours

@implementation MMEEventsConfiguration

+ (instancetype)defaultEventsConfiguration {
    MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
    configuration.eventFlushCountThreshold = kEventFlushCountThresholdDefault;
    configuration.eventFlushSecondsThreshold = kEventFlushSecondsThresholdDefault;
    configuration.instanceIdentifierRotationTimeInterval = kInstanceIdentifierRotationTimeIntervalDefault;
    configuration.configurationRotationTimeInterval = kConfigurationRotationTimeIntervalDefault;
    configuration.locationManagerHibernationRadius = kHibernationRadiusDefault;
    return configuration;
}

+ (instancetype)eventsConfigurationWithVariableRadius:(CLLocationDistance)radius delay:(NSTimeInterval)delay {
    MMEEventsConfiguration *configuration = [self defaultEventsConfiguration];

    if (radius < kHibernationRadiusDefault) radius = kHibernationRadiusDefault;
    else if (radius > kHibernationRadiusWide) radius = kHibernationRadiusWide;

    configuration.locationManagerHibernationRadius = radius;
    configuration.initializationDelay = delay;
    return configuration;
}

+ (instancetype)configurationWithInfoDictionary:(NSDictionary *)infoDictionary {
    NSString *profileName = infoDictionary[kMMEEventsProfile];
    if ([profileName isEqualToString:kMMECustomProfile]) {
        id customRadiusNumber = infoDictionary[kMMERadiusSize];
        CLLocationDistance customRadius = [customRadiusNumber isKindOfClass:[NSNumber class]] ? [customRadiusNumber doubleValue] : 1200.0;

        id initializationDelayNumber = infoDictionary[kMMEStartupDelay];
        NSTimeInterval initializationDelay = [initializationDelayNumber isKindOfClass:[NSNumber class]] ? [initializationDelayNumber doubleValue] : 10;

        return [MMEEventsConfiguration eventsConfigurationWithVariableRadius:customRadius delay:initializationDelay];
    } else {
        return [MMEEventsConfiguration defaultEventsConfiguration];
    }
}

+ (instancetype)configuration {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return [self configurationWithInfoDictionary:infoDictionary];
}

@end
