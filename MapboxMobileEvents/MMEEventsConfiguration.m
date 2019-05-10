#import "MMEEventsConfiguration.h"
#import "MMEMetricsManager.h"

static NSString *const kMMEEventsProfile = @"MMEEventsProfile";
static NSString *const kMMERadiusSize = @"MMECustomGeofenceRadius";
static NSString *const kMMEStartupDelay = @"MMEStartupDelay";
static NSString *const kMMECustomProfile = @"Custom";

static const CLLocationDistance kHibernationRadiusDefault = 300.0;
static const CLLocationDistance kHibernationRadiusWide = 1200.0;
static const NSUInteger kEventFlushCountThresholdDefault = 10;
static const NSUInteger kEventFlushSecondsThresholdDefault = 10;
static const NSTimeInterval kInitDelayTimeInterval = 10;
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
        CLLocationDistance customRadius = [customRadiusNumber isKindOfClass:[NSNumber class]] ? [customRadiusNumber doubleValue] : kHibernationRadiusWide;

        id initializationDelayNumber = infoDictionary[kMMEStartupDelay];
        NSTimeInterval initializationDelay = [initializationDelayNumber isKindOfClass:[NSNumber class]] ? [initializationDelayNumber doubleValue] : kInitDelayTimeInterval;

        return [MMEEventsConfiguration eventsConfigurationWithVariableRadius:customRadius delay:initializationDelay];
    } else {
        return [MMEEventsConfiguration defaultEventsConfiguration];
    }
}

+ (instancetype)configuration {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return [self configurationWithInfoDictionary:infoDictionary];
}

+ (instancetype)configurationFromData:(NSData *)data {
    MMEEventsConfiguration *configuration = [self configuration];
    [self parseJSONFromData:data withConfiguration:configuration];
    return configuration;
}

#pragma mark - Utilities

+ (void)parseJSONFromData:(NSData *)data withConfiguration:(MMEEventsConfiguration *)configuration {
    if (!data) {
        return;
    }
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    
    if (!jsonError) {
        [[MMEMetricsManager sharedManager] updateConfigurationJSON:json];
        NSArray *blacklist = [json objectForKey:@"RevokedCertKeys"];
        configuration.blacklist = blacklist;
    }
}

@end
