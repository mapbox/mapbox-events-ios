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
