#import "MMEUIApplicationWrapper.h"

@implementation MMEUIApplicationWrapper

- (UIApplicationState)applicationState {
    return [UIApplication sharedApplication].applicationState;
}

@end
