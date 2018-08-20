#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"
#import "MMEAPIClient.h"

@protocol MMEConfigurationUpdaterDelegate <NSObject>

- (void)configurationDidUpdate:(MMEEventsConfiguration *)configuration;

@end

@interface MMEConfigurationUpdater : NSObject

- (instancetype)init __attribute__((unavailable("This method is not available")));
- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval;
- (void)updateConfigurationFromAPIClient:(MMEAPIClient *)apiClient;

@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic, weak) id <MMEConfigurationUpdaterDelegate> delegate;

@end
