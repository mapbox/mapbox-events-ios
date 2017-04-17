#import "MapboxMobileEvents.h"
#import "MMEEventsManager.h"
#import "MMELocationManager.h"

@implementation MapboxMobileEvents

- (NSString *)sayHelloTo:(NSString *)name {
    [[MMEEventsManager sharedManager].locationManager startUpdatingLocation];
    return [NSString stringWithFormat:@"hello %@", name];
}

@end
