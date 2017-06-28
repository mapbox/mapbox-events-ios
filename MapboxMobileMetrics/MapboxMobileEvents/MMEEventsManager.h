#import <Foundation/Foundation.h>
#import "MMEEvent.h"
#import "MMETypes.h"

@class MMELocationManager;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventsManager : NSObject

@property (nonatomic, getter=isMetricsEnabled) BOOL metricsEnabled;
@property (nonatomic, getter=isMetricsEnabledInSimulator) BOOL metricsEnabledInSimulator;
@property (nonatomic, getter=isDebugLoggingEnabled) BOOL debugLoggingEnabled;
@property (nonatomic) NSNumber *accountTypeNumber;

+ (nullable instancetype)sharedManager;

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion;

- (void)sendTurnstileEvent;
- (void)enqueueEventWithName:(NSString *)name;
- (void)enqueueEventWithName:(NSString *)name attributes:(MMEMapboxEventAttributes *)attributes;
- (void)pauseOrResumeMetricsCollectionIfRequired;

@end

NS_ASSUME_NONNULL_END
