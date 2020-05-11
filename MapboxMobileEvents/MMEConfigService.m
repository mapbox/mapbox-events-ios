#import "MMEConfigService.h"
#import "MMEEventConfigProviding.h"

@interface MMEConfigService ()

/*! Poll Timer */
@property (nullable, nonatomic) NSTimer *timer;

@end

@implementation MMEConfigService

- (instancetype)init:(id <MMEEventConfigProviding>)config
              client:(MMEAPIClient*)client
        onConfigLoad:(OnConfigLoad)onConfigLoad {

    if (self = [super init]) {
        _config = config;
        _client = client;
        _onConfigLoad = onConfigLoad;
    }

    return self;
}

- (void)startUpdates {

    __weak __typeof__(self) weakSelf = self;

    // Configure Timer Polling
    if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) {
        self.timer = [NSTimer
                      scheduledTimerWithTimeInterval:self.config.mme_configUpdateInterval
                      repeats:YES
                      block:^(NSTimer * _Nonnull timer) {

            [weakSelf.client getEventConfigWithCompletionHandler:^(
                                                                     MMEConfig * _Nullable config,
                                                                     NSError * _Nullable error) {
                if (config) {
                    weakSelf.onConfigLoad(config);
                }

            }];
        }];
        self.timer.tolerance = 60;
    }
}

- (void)stopUpdates {
        [self.timer invalidate];
        self.timer = nil;
}

@end
