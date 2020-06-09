#import "MMEUIApplicationWrapper.h"

@interface MMEUIApplicationWrapper ()
@property (nonatomic, strong) id <MMEUIApplicationWrapper> application;
@end

@implementation MMEUIApplicationWrapper

// MARK: - Initializers

- (instancetype)init {
    return [self initWithApplication:UIApplication.sharedApplication];
}

- (instancetype)initWithApplication:(id<MMEUIApplicationWrapper>)application {
    if (self = [super init]) {
        self.application = application;
    }
    return self;
}

// MARK: - Properties

- (UIApplicationState)applicationState {
    return self.application.applicationState;
}

// MARK: - Methods

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^ __nullable)(void))handler {
    return [self.application beginBackgroundTaskWithExpirationHandler:handler];
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
    [self.application endBackgroundTask:identifier];
}

@end

@implementation MMEUIApplicationExtensionWrapper

// MARK: - Properties

- (UIApplicationState)applicationState {
    return UIApplicationStateActive;
}

// MARK: - Methods

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^ __nullable)(void))handler {
    // No-Op. Extensions don't support background tasks
    // Potentially leverage
    // https://developer.apple.com/documentation/foundation/nsprocessinfo/1617030-performexpiringactivitywithreaso?language=objc
    return UIBackgroundTaskInvalid;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
    // no-op
}

@end
