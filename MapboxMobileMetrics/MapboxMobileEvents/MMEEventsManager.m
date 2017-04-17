#import "MMEEventsManager.h"
#import "MMELocationManager.h"

@interface MMEEventsManager () <MMELocationManagerDelegate>

@property (nonatomic, readwrite) MMELocationManager *locationManager;

@end

@implementation MMEEventsManager

+ (void)load {
    [self sharedManager];
}

+ (nullable instancetype)sharedManager {
//    if (NSProcessInfo.processInfo.mgl_isInterfaceBuilderDesignablesAgent) {
//        return nil;
//    }

    static MMEEventsManager *_sharedManager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedManager = [[MMEEventsManager alloc] init];
    });

    return _sharedManager;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _locationManager = [[MMELocationManager alloc] init];
        _locationManager.delegate = self;
    }

    return self;
}

#pragma mark - MMELocationManagerDelegate

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    NSLog(@"================> %s", __PRETTY_FUNCTION__);
}

@end
