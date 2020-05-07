#import <Foundation/Foundation.h>
#import "MMEEventConfigProviding.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief Mock Immutable Config */
@interface MMEMockEventConfig : NSObject <MMEEventConfigProviding>

/// Interval to wait before starting up when the application launches
@property (nonatomic, readonly) NSTimeInterval mme_startupDelay;

/// Number of events to put into a batch, the MMEEventsManager will flush it's queue at this threshold
@property (nonatomic, readonly) NSUInteger mme_eventFlushCount;

/// Maximum Time interval between event flush
@property (nonatomic, readonly) NSTimeInterval mme_eventFlushInterval;

/// Interval at which we rotate the unique identifier for this SDK instance
@property (nonatomic, readonly) NSTimeInterval mme_identifierRotationInterval;

/// Interval at which we check for updated configuration
@property (nonatomic, readonly) NSTimeInterval mme_configUpdateInterval;

/// Tag for events
@property (nonatomic, readonly) NSString *mme_eventTag;

// MARK: - Volatile Configuration

/// Access Token
@property (nonatomic, copy, readonly) NSString *mme_accessToken;

/// User-Agent Base
@property (nonatomic, copy, readonly) NSString *mme_legacyUserAgentBase;

/// Host SDK Version
@property (nonatomic, copy, readonly) NSString *mme_legacyHostSDKVersion;

/// CN Region Setting
@property (nonatomic, assign, readonly) BOOL mme_isCNRegion;

// MARK: - Service Configuration

/// API Service URL for the current region
@property (nonatomic, readonly) NSURL *mme_APIServiceURL;

/// Events Service URL for the current region
@property (nonatomic, readonly) NSURL *mme_eventsServiceURL;

/// Config Service URL for the current region
@property (nonatomic, readonly) NSURL *mme_configServiceURL;

/// Reformed User-Agent String
@property (nonatomic, readonly) NSString *mme_userAgentString;

/// Legacy User-Agent String
@property (nonatomic, readonly) NSString *mme_legacyUserAgentString;

// MARK: - Location Collection

/// This property is only settable by the end user
@property (nonatomic, readonly) BOOL mme_isCollectionEnabled;

/// This property is volatile
@property (nonatomic, readonly) BOOL mme_isCollectionEnabledInSimulator;

// MARK: - Background Collection

/// Bool, is background collection enabled
@property (nonatomic, readonly) BOOL mme_isCollectionEnabledInBackground;

/// Interval to wait before starting telemetry collection in the background
@property (nonatomic, readonly) NSTimeInterval mme_backgroundStartupDelay;

/// Distance to set for the background collection geo-fence
@property (nonatomic, readonly) CLLocationDistance mme_backgroundGeofence;

// MARK: - Certificate Pinning and Revocation

/// An array of revoked public key hashes
@property (nonatomic, copy, readonly) NSArray<NSString *>*mme_certificateRevocationList;

/// The Certificate Pinning config
@property (nonatomic, copy, readonly) NSDictionary *mme_certificatePinningConfig;

/*! @brief Default Values Initializer */
- (instancetype)init;

/*! @brief Designated Initializer */
- (instancetype)initWithStartupDelay:(NSTimeInterval)startupDelay
                     eventFlushCount:(NSUInteger)flushCount
                       flushInterval:(NSUInteger)flushInterval
          identifierRotationInterval:(NSTimeInterval)identifierRotationInterval
                configUpdateInterval:(NSTimeInterval)configUpdateInterval
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
                 isCollectionEnabled:(BOOL)isCollectionEnabled
      isCollectionEnabledInSimulator:(BOOL)isCollectionEnabledInSimulator
     isCollectionEnabledInBackground:(BOOL)isCollectionEnabledInBackground
              backgroundStartupDelay:(NSTimeInterval)backgroundStartupDelay
                  backgroundGeofence:(CLLocationDistance)backgroundGeofence
           certificateRevocationList:(NSArray<NSString*>*)certificationRevocationList
            certificatePinningConfig:(NSDictionary<NSString*, NSArray<NSString*>*>*)certificatePinningConfig;
@end

NS_ASSUME_NONNULL_END
