@import Foundation;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@class MMEDate;

/// Provides the necessary readonly config values for determining behaviors
@protocol MMEEventConfigProviding <NSObject>

// MARK: - Event Manager Configuration

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

@property (nullable, nonatomic, readonly) MMEDate* mme_configUpdateDate;

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

@end

NS_ASSUME_NONNULL_END
