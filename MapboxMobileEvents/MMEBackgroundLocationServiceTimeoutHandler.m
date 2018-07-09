#import "MMEBackgroundLocationServiceTimeoutHandler.h"
#import "MMEUIApplicationWrapper.h"

static const NSTimeInterval MMELocationManagerHibernationTimeout = 300.0;
static const NSTimeInterval MMELocationManagerHibernationPollInterval = 5.0;

@interface MMEBackgroundLocationServiceTimeoutHandler ()

@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) NSDate *backgroundLocationServiceTimeoutAllowedDate;
@property (nonatomic) NSTimer *backgroundLocationServiceTimeoutTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundLocationServiceTimeoutTaskId;

@end

#pragma mark - MMEBackgroundLocationServiceTimeoutHandler

@implementation MMEBackgroundLocationServiceTimeoutHandler

- (instancetype)initWithApplication:(id<MMEUIApplicationWrapper>)application {
    self = [super init];
    if (self) {
        _application = application;
    }
    return self;
}

- (void)timeoutAllowedCheck:(NSTimer *)timer {
    id<MMEBackgroundLocationServiceTimeoutHandlerDelegate> delegate = self.delegate;

    if (!delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopBackgroundTimeoutTimer];
        });
        return;
    }

    if (![delegate timeoutHandlerShouldCheckForTimeout:self]) {
        self.backgroundLocationServiceTimeoutAllowedDate = [[NSDate date] dateByAddingTimeInterval:MMELocationManagerHibernationTimeout];
        return;
    }

    if (!self.backgroundLocationServiceTimeoutAllowedDate) {
        return;
    }

    NSTimeInterval timeIntervalSinceTimeoutAllowed = [[NSDate date] timeIntervalSinceDate:self.backgroundLocationServiceTimeoutAllowedDate];
    if (timeIntervalSinceTimeoutAllowed > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopBackgroundTimeoutTimer];
            [delegate timeoutHandlerDidTimeout:self];
        });
    }
}

- (void)startBackgroundTimeoutTimer {
    if (self.backgroundLocationServiceTimeoutTimer) {
        return;
    }

    __weak __typeof__(self) weakself = self;
    NSAssert(self.backgroundLocationServiceTimeoutTaskId == UIBackgroundTaskInvalid, @"Background task Id should be invalid");
    self.backgroundLocationServiceTimeoutTaskId = [self.application beginBackgroundTaskWithExpirationHandler:^{
        [weakself stopBackgroundTimeoutTimer];
    }];

    self.backgroundLocationServiceTimeoutAllowedDate = [[NSDate date] dateByAddingTimeInterval:MMELocationManagerHibernationTimeout];
    self.backgroundLocationServiceTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:MMELocationManagerHibernationPollInterval target:self selector:@selector(timeoutAllowedCheck:) userInfo:nil repeats:YES];
}

- (void)stopBackgroundTimeoutTimer {
    if (UIBackgroundTaskInvalid != self.backgroundLocationServiceTimeoutTaskId) {
        [self.application endBackgroundTask:self.backgroundLocationServiceTimeoutTaskId];
        self.backgroundLocationServiceTimeoutTaskId = UIBackgroundTaskInvalid;
    }

    [self.backgroundLocationServiceTimeoutTimer invalidate];
    self.backgroundLocationServiceTimeoutTimer = nil;
    self.backgroundLocationServiceTimeoutAllowedDate = nil;
}

@end
