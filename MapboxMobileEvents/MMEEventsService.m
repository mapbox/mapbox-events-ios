#import "MMEEventsService.h"

NSString *const kMMEEventsProfile = @"MMEEventsProfile";
NSString *const kMMERadiusSize = @"MMECustomGeofenceRadius";
NSString *const kMMEStartupDelay = @"MMEStartupDelay";

static NSString *const kMMECustomProfile = @"Custom";

@implementation MMEEventsService

- (instancetype) init {
    self = [super init];
    if (self) {
        self.configuration = [self configurationFromKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:kMMEEventsProfile]];
//        self.configuration = [MMEEventsConfiguration configurationWithInfoDictionary:[[NSBundle mainBundle] infoDictionary]];
    }
    return self;
}

+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    static MMEEventsService *_sharedService;
    dispatch_once(&onceToken, ^{
        _sharedService = [[self alloc] init];
    });
    return _sharedService;
}

- (MMEEventsConfiguration *)configurationFromKey:(NSString *)key {
    if ([key isEqualToString:kMMECustomProfile]) {
        if ([[NSBundle mainBundle] objectForInfoDictionaryKey:kMMERadiusSize]) {
            NSNumber *customRadius = [[NSBundle mainBundle] objectForInfoDictionaryKey:kMMERadiusSize];
            return [MMEEventsConfiguration eventsConfigurationWithVariableRadius:customRadius.doubleValue];
        } else {
            return [MMEEventsConfiguration eventsConfigurationWithVariableRadius:1200.0];
        }
    } else {
        return [MMEEventsConfiguration defaultEventsConfiguration];
    }
    return nil;
}

@end
