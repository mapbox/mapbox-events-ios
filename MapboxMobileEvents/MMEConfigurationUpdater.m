#import "MMEConfigurationUpdater.h"
#import "MMEAPIClient.h"

@interface MMEConfigurationUpdater ()

@property (nonatomic) NSDate *configurationRotationDate;

@end

@implementation MMEConfigurationUpdater

- (void)updateConfigurationFromAPIClient:(MMEAPIClient *)apiClient {
    [apiClient getBlacklistWithCompletionHandler:^(NSError * _Nullable error, NSArray * _Nullable blacklist) {
        if (!error) {
            MMEEventsConfiguration *configuration = [MMEEventsConfiguration configuration];
            configuration.blacklist = blacklist;
            
            [self.delegate configurationDidUpdate:configuration];
        }
    }];
}


@end
