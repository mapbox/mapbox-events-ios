#import <Foundation/Foundation.h>
#import "MMEEvent.h"
#import "MMETypes.h"
#import <CoreLocation/CoreLocation.h>


@class MMELocationManager;

NS_ASSUME_NONNULL_BEGIN

@protocol MMEEventsManagerDelegate;

@protocol MMEEventsManagerDelegate <NSObject>

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray<CLLocation *> *)locations;

@end

@interface MMEEventsManager : NSObject

@property (nonatomic, weak) id<MMEEventsManagerDelegate> delegate;
@property (nonatomic, getter=isMetricsEnabled) BOOL metricsEnabled;
@property (nonatomic, getter=isMetricsEnabledInSimulator) BOOL metricsEnabledInSimulator;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;
@property (nonatomic, getter=isDebugLoggingEnabled) BOOL debugLoggingEnabled;
@property (nonatomic, readonly) NSString *userAgentBase;
@property (nonatomic, readonly) NSString *hostSDKVersion;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, null_resettable) NSURL *baseURL;
@property (nonatomic) NSInteger accountType;

+ (instancetype)sharedManager;

- (void)initializeWithAccessToken:(NSString *)accessToken userAgentBase:(NSString *)userAgentBase hostSDKVersion:(NSString *)hostSDKVersion;

- (void)pauseOrResumeMetricsCollectionIfRequired;
- (void)flush;
- (void)sendTurnstileEvent;
- (void)enqueueEventWithName:(NSString *)name;
- (void)enqueueEventWithName:(NSString *)name attributes:(MMEMapboxEventAttributes *)attributes;
- (void)disableLocationMetrics;

- (void)displayLogFileFromDate:(NSDate *)logDate;

@end


NS_ASSUME_NONNULL_END
