#import "MMEConfigurationUpdater.h"
#import "MMEAPIClient.h"

@interface MMEConfigurationUpdater ()

@property (nonatomic) NSDate *configurationRotationDate;
@property (nonatomic, copy) MMEEventsConfiguration *configuration;

@end

@implementation MMEConfigurationUpdater

- (instancetype)init {
    NSAssert(false, @"Use `-[MMEConfigurationUpdater initWithTimeInterval:]` to create instances of this class.");
    return nil;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        _timeInterval = timeInterval;
    }
    return self;
}

- (void)updateConfigurationFromAPIClient:(MMEAPIClient *)apiClient {
    if (self.configurationRotationDate && [[NSDate date] timeIntervalSinceDate:self.configurationRotationDate] >= 0) {
        self.configuration = nil;
    }
    if (!self.configuration) {
        [apiClient getConfigurationWithCompletionHandler:^(NSError * _Nullable error, NSData * _Nullable data) {
            if (!error) {
                self.configuration = [MMEEventsConfiguration configurationFromData:data];
                
                [self.delegate configurationDidUpdate:self.configuration];
                self.configurationRotationDate = [[NSDate date] dateByAddingTimeInterval:self.timeInterval];
            }
        }];
    }
}

@end
