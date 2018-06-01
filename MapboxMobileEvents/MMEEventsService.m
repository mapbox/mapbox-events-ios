#import "MMEEventsService.h"

NSString *const kMMEEventsProfile = @"MMEEventsProfile";
NSString *const kMMERadiusSize = @"MMEGeofenceRadius";

static NSString *const kConfigHibernationRadiusVariableKey = @"VariableGeofence";

@implementation MMEEventsService

- (instancetype) init {
    self = [super init];
    if (self) {
        self.configuration = [self configurationFromKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:kMMEEventsProfile]];
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
    if ([key isEqualToString:kConfigHibernationRadiusVariableKey]) {
        return [MMEEventsConfiguration eventsConfigurationWithVariableRadius:[[[NSBundle mainBundle] objectForInfoDictionaryKey:kMMERadiusSize] doubleValue]];
    } else {
        return [MMEEventsConfiguration defaultEventsConfiguration];
    }
    return nil;
}

@end
