#import <Foundation/Foundation.h>
#import "MMEEventConfigProviding.h"
#import <CoreLocation/CLLocation.h>

@class MMEDate;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Mock Immutable Config */
@interface MMEMockEventConfig : NSObject <MMEEventConfigProviding>

/// Interval to wait before starting up when the application launches
@property (nonatomic, assign) NSTimeInterval startupDelay;

/// Number of events to put into a batch, the MMEEventsManager will flush it's queue at this threshold
@property (nonatomic, assign) NSUInteger eventFlushCount;

/// Maximum Time interval between event flush
@property (nonatomic, assign) NSTimeInterval eventFlushInterval;

/// Most Recent date config was updated
@property (nonatomic) MMEDate* configUpdateDate;

/// Interval at which we rotate the unique identifier for this SDK instance
@property (nonatomic, assign) NSTimeInterval identifierRotationInterval;

/// Interval at which we check for updated configuration
@property (nonatomic, assign) NSTimeInterval configUpdateInterval;

/// Tag for events
@property (nonatomic, copy) NSString *eventTag;

// MARK: - Volatile Configuration

/// Access Token
@property (nullable, nonatomic, copy) NSString *accessToken;

/// User-Agent Base
@property (nullable, nonatomic, copy) NSString *legacyUserAgentBase;

/// Host SDK Version
@property (nullable, nonatomic, copy) NSString *legacyHostSDKVersion;

@property (nonatomic, copy) NSString *clientId;

/// China Region Setting
@property (nonatomic, assign) BOOL isChinaRegion;

// MARK: - Service Configuration

/// API Service URL for the current region
@property (nonatomic, copy) NSURL *apiServiceURL;

/// Events Service URL for the current region
@property (nonatomic, copy) NSURL *eventsServiceURL;

/// Config Service URL for the current region
@property (nonatomic, copy) NSURL *configServiceURL;

/// Reformed User-Agent String
@property (nonatomic, copy) NSString *userAgentString;

/// Legacy User-Agent String
@property (nonatomic, copy) NSString *legacyUserAgentString;

// MARK: - Location Collection

/// This property is only settable by the end user
@property (nonatomic, assign) BOOL isCollectionEnabled;

/// This property is volatile
@property (nonatomic, assign) BOOL isCollectionEnabledInSimulator;

// MARK: - Background Collection

/// Bool, is background collection enabled
@property (nonatomic, assign) BOOL isCollectionEnabledInBackground;

/// Interval to wait before starting telemetry collection in the background
@property (nonatomic, assign) NSTimeInterval backgroundStartupDelay;

/// Distance to set for the background collection geo-fence
@property (nonatomic, assign) CLLocationDistance backgroundGeofence;

// MARK: - Certificate Pinning and Revocation

/// An array of revoked public key hashes
@property (nonatomic, copy) NSArray<NSString *>*certificateRevocationList;

/// The Certificate Pinning config
@property (nonatomic, copy) NSDictionary *certificatePinningConfig;

/*! @brief Default Values Initializer */
- (instancetype)init;

/*! @brief Designated Initializer */
- (instancetype)initWithStartupDelay:(NSTimeInterval)startupDelay
                     eventFlushCount:(NSUInteger)eventFlushCount
                  eventFlushInterval:(NSUInteger)eventFlushInterval
          identifierRotationInterval:(NSTimeInterval)identifierRotationInterval
                configUpdateInterval:(NSTimeInterval)configUpdateInterval
                    lastConfigUpdate:(NSDate*)lastConfigUpdate
                            eventTag:(NSString*)eventTag
                         accessToken:(NSString*)accessToken
                 legacyUserAgentBase:(NSString*)legacyUserAgentBase
                legacyHostSDKVersion:(NSString*)legacyHostSDKVersion
                       isChinaRegion:(BOOL)isChinaRegion
                              apiURL:(NSURL*)apiURL
                           eventsURL:(NSURL*)eventsURL
                           configURL:(NSURL*)configURL
                           userAgent:(NSString*)userAgent
                     legacyUserAgent:(NSString*)legacyUserAgent
                            clientId:(NSString*)clientId
                 isCollectionEnabled:(BOOL)isCollectionEnabled
      isCollectionEnabledInSimulator:(BOOL)isCollectionEnabledInSimulator
     isCollectionEnabledInBackground:(BOOL)isCollectionEnabledInBackground
              backgroundStartupDelay:(NSTimeInterval)backgroundStartupDelay
                  backgroundGeofence:(CLLocationDistance)backgroundGeofence
           certificateRevocationList:(NSArray<NSString*>*)certificationRevocationList
            certificatePinningConfig:(NSDictionary<NSString*, NSArray<NSString*>*>*)certificatePinningConfig NS_DESIGNATED_INITIALIZER;

/*! @Brief Defaults (except Update Interface is 1s) targeting local host */
+ (instancetype)oneSecondConfigUpdate;

@end

NS_ASSUME_NONNULL_END
