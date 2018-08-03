#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"
#import "MMEAPIClient.h"

@protocol MMEConfigurationUpdaterDelegate <NSObject>

- (void)configurationDidUpdate:(MMEEventsConfiguration *)configuration;

@end

@interface MMEConfigurationUpdater : NSObject

@property (nonatomic, weak) id <MMEConfigurationUpdaterDelegate> delegate;
- (void)updateConfigurationFromAPIClient:(MMEAPIClient *)apiClient;

@end
