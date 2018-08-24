#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"
#import "MMEAPIClient.h"

@protocol MMEConfigurationUpdaterDelegate <NSObject>

- (void)configurationDidUpdate:(MMEEventsConfiguration *)configuration;

@end

@interface MMEConfigurationUpdater : NSObject

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval NS_DESIGNATED_INITIALIZER;
- (void)updateConfigurationFromAPIClient:(MMEAPIClient *)apiClient;

@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic, weak) id <MMEConfigurationUpdaterDelegate> delegate;

@end
