#import "MMEUIApplicationWrapperFake.h"

@implementation MMEUIApplicationWrapperFake

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^ _Nullable)(void))handler {
    return 0;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
}

@end

