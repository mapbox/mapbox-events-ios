#import "MMEDependencyManager.h"
#import <CoreLocation/CoreLocation.h>

@implementation MMEDependencyManager

- (CLLocationManager *)locationManagerInstance {
    return [[CLLocationManager alloc] init];
}

@end
