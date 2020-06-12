#import "MMEConfigService.h"
#import "MMEConfigurationProviding.h"
#import "MMEDate.h"

@interface MMEConfigService ()

/*! Poll Timer */
@property (nullable, nonatomic) NSTimer *timer;
@property (nonatomic, copy) OnConfigLoad onConfigLoad;

@end

@implementation MMEConfigService

- (instancetype)init:(id <MMEConfigurationProviding>)config
              client:(MMEAPIClient*)client
        onConfigLoad:(OnConfigLoad)onConfigLoad {

    if (self = [super init]) {
        _config = config;
        _client = client;
        self.onConfigLoad = onConfigLoad;
    }

    return self;
}

- (void)startUpdates {

    __weak __typeof__(self) weakSelf = self;

    // Configure Timer Polling
    if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) {
        self.timer = [NSTimer
                      scheduledTimerWithTimeInterval:self.config.configUpdateInterval
                      repeats:YES
                      block:^(NSTimer * _Nonnull timer) {

            if (weakSelf) {
                [weakSelf.client getEventConfigWithCompletionHandler:^(
                                                                       MMEConfig * _Nullable config,
                                                                       NSError * _Nullable error) {
                    __strong __typeof__(weakSelf) strongSelf = weakSelf;
                    if (strongSelf) {
                        if (config) {
                            strongSelf.onConfigLoad(config);
                        }
                    }
                }];
            }
        }];
        
        self.timer.tolerance = 60;

        // Manually Fetch if last updated date is older than our update interval
        // TODO: - Given we're setting our time interval upon initialization, it could be quite a ways in the future. I wonder if we should fetch on init, then set a timer to repeat upon completion? Or perhaps set a timer based on a fire date calculated from last update?
        if (!self.config.configUpdateDate ||
            (fabs(self.config.configUpdateDate.timeIntervalSinceNow) > self.config.configUpdateInterval)) {
            [self.timer fire];
        }
    }
}

- (void)stopUpdates {
        [self.timer invalidate];
        self.timer = nil;
}

@end
