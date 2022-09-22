#import "MMEDependencyManager.h"
#import <CoreLocation/CoreLocation.h>

static MMEDependencyManager *_sharedInstance;

@implementation MMEDependencyManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[MMEDependencyManager alloc] init];
    });
    return _sharedInstance;
}

- (CLLocationManager *)locationManagerInstance {
    NSAssert([NSThread isMainThread], @"CLLocationManager should be created only on the main thread");
    return [[CLLocationManager alloc] init];
}

@end
