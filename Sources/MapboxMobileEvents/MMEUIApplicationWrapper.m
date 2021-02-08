#import "MMEUIApplicationWrapper.h"
#import "NSBundle+MMEMobileEvents.h"
#import "UIKit+MMEMobileEvents.h"

// MARK: - App Extension Support

/*! Provides Wrapper Getters for Non UIApplication Interfaces */
@interface MMEUIApplicationExtensionWrapper : NSObject <MMEUIApplicationWrapper>
@end

// MARK: -

@implementation MMEUIApplicationExtensionWrapper

// MARK: Properties

- (NSInteger)mme_contentSizeScale {
    return NSExtensionContext.mme_contentSizeScale;
}

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

// MARK: -

@interface MMEUIApplicationWrapper ()
@property (nonatomic, strong) id <MMEUIApplicationWrapper> application;
@end

// MARK: -

@implementation MMEUIApplicationWrapper

// MARK: Initializers

- (instancetype)init {

    // Check if Extension
    if (NSBundle.mme_isExtension) {
        return [self initWithApplication:MMEUIApplicationExtensionWrapper.new];
    }else if ([[UIApplication class] respondsToSelector:@selector(sharedApplication)]) {

        // If UIApplication is available use it
        // This is second as UIApplication may be available for paired extensions
        return [self initWithApplication:[[UIApplication class] performSelector:@selector(sharedApplication)]];
    } else {

        // Otherwise default to the general Fallback pulling information from Non UIApplication Sources
        return [self initWithApplication:MMEUIApplicationExtensionWrapper.new];
    }

}

- (instancetype)initWithApplication:(id<MMEUIApplicationWrapper>)application {
    if (self = [super init]) {
        self.application = application;
    }
    return self;
}

// MARK: - Properties

- (NSInteger)mme_contentSizeScale {
    return self.application.mme_contentSizeScale;
}

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
