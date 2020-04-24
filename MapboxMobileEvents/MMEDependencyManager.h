#import <Foundation/Foundation.h>
#import "MMEDependencyProviding.h"

@class CLLocationManager;

// Consider new name? What is this managing?
@interface MMEDependencyManager : NSObject <MMEDependencyProviding>

- (CLLocationManager *)locationManagerInstance;

@end
