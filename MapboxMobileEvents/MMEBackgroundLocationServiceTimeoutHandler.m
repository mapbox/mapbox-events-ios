#import "MMEBackgroundLocationServiceTimeoutHandler.h"
#import "MMEUIApplicationWrapper.h"

static const NSTimeInterval MMELocationManagerHibernationTimeout = 300.0;
static const NSTimeInterval MMELocationManagerHibernationPollInterval = 5.0;

@interface MMEBackgroundLocationServiceTimeoutHandler ()

@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) NSDate *expiration;
@property (nonatomic, readwrite) NSTimer *timer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

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
            [self stopTimer];
        });
        return;
    }

    if (![delegate timeoutHandlerShouldCheckForTimeout:self]) {
        self.expiration = [[NSDate date] dateByAddingTimeInterval:MMELocationManagerHibernationTimeout];
        return;
    }

    if (!self.expiration) {
        return;
    }

    NSTimeInterval timeIntervalSinceTimeoutAllowed = [[NSDate date] timeIntervalSinceDate:self.expiration];
    if (timeIntervalSinceTimeoutAllowed > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopTimer];
            [delegate timeoutHandlerDidTimeout:self];
        });
    }
}

- (void)startTimer {
    if (self.timer) {
        return;
    }

    __weak __typeof__(self) weakself = self;
    NSAssert(self.backgroundTaskId == UIBackgroundTaskInvalid, @"Background task Id should be invalid");
    self.backgroundTaskId = [self.application beginBackgroundTaskWithExpirationHandler:^{
        __typeof__(self) strongSelf = weakself;

        [strongSelf stopTimer];
        [strongSelf.delegate timeoutHandlerBackgroundTaskDidExpire:strongSelf];
    }];

    self.expiration = [[NSDate date] dateByAddingTimeInterval:MMELocationManagerHibernationTimeout];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:MMELocationManagerHibernationPollInterval target:self selector:@selector(timeoutAllowedCheck:) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    if (UIBackgroundTaskInvalid != self.backgroundTaskId) {
        [self.application endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }

    [self.timer invalidate];
    self.timer = nil;
    self.expiration = nil;
}

@end
