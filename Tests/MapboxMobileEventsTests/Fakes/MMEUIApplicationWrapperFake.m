#import "MMEUIApplicationWrapperFake.h"

@implementation MMEUIApplicationWrapperFake

- (NSInteger)mme_contentSizeScale {
    return 0;
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^ _Nullable)(void))handler {
    
    _backgroundTaskExpirationHandlerBlock = handler;
    
    return self.backgroundTaskIdentifier;
}

- (void)executeBackgroundTaskExpirationWithCompletionHandler {
    if (self.backgroundTaskExpirationHandlerBlock) {
        self.backgroundTaskExpirationHandlerBlock();
    }
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
}

@end

