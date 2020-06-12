#import "MMEAPIClient.h"

@class MMEAPIClient;
@class MMEConfig;
@protocol MMEConfigurationProviding;

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnConfigLoad)(MMEConfig *config);

/*! Manages Configuration Fetching  */
@interface MMEConfigService : NSObject

/*! Configuration describing differentiated config fetching behaviors */
@property (nonatomic, readonly) id <MMEConfigurationProviding> config;

/*! Block Called on Each Config Load (On Main Thread) */
@property (nonatomic, copy, readonly) OnConfigLoad onConfigLoad;


/*! Client to make API Calls */
@property (nonatomic, readonly) MMEAPIClient* client;

/*!
 @Brief Initializer
 @Param config Configuration describing differentiated config fetching behaviors
 @param client Client used to make API calls
 @param onConfigLoad Block for reacting to Configuration update responses
 */
- (instancetype)init:(id <MMEConfigurationProviding>)config
              client:(MMEAPIClient*)client
        onConfigLoad:(OnConfigLoad)onConfigLoad;

/*!
 @brief Start the Configuration update process (Periodically Fetched)
 @discussion If last update is older than update interval fetches immediately. Otherwise, fetches on a configured time
 */
- (void)startUpdates;

/// Stop the Configuration update process
- (void)stopUpdates;

@end

NS_ASSUME_NONNULL_END
