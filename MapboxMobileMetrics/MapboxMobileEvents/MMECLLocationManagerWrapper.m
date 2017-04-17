#import "MMECLLocationManagerWrapper.h"

@implementation MMECLLocationManagerWrapper

- (CLAuthorizationStatus)authorizationStatus {
    return [CLLocationManager authorizationStatus];
}

@end
