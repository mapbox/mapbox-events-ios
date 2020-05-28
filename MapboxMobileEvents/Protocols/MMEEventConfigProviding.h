@import Foundation;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@class MMEDate;

/// Provides the necessary readonly config values for determining behaviors
@protocol MMEEventConfigProviding <NSObject>

// MARK: - Event Manager Configuration

/// Interval to wait before starting up when the application launches
@property (nonatomic, readonly) NSTimeInterval startupDelay;

/// Number of events to put into a batch, the MMEEventsManager will flush it's queue at this threshold
@property (nonatomic, readonly) NSUInteger eventFlushCount;

/// Maximum Time interval between event flush
@property (nonatomic, readonly) NSTimeInterval eventFlushInterval;

/// Interval at which we rotate the unique identifier for this SDK instance
@property (nonatomic, readonly) NSTimeInterval identifierRotationInterval;

/// Interval at which we check for updated configuration
@property (nonatomic, readonly) NSTimeInterval configUpdateInterval;

@property (nullable, nonatomic, readonly) MMEDate* configUpdateDate;

/// Tag for events
@property (nonatomic, copy, readonly) NSString *eventTag;

// MARK: - Volatile Configuration

/// Access Token
@property (nullable, nonatomic, copy, readonly) NSString *accessToken;

/// User-Agent Base
@property (nullable, nonatomic, copy, readonly) NSString *legacyUserAgentBase;

/// Host SDK Version
@property (nullable, nonatomic, copy, readonly) NSString *legacyHostSDKVersion;

/// CN Region Setting
@property (nonatomic, assign, readonly) BOOL isChinaRegion;

// MARK: - Service Configuration

/// API Service URL for the current region
@property (nonatomic, copy, readonly) NSURL *apiServiceURL;

/// Events Service URL for the current region
@property (nonatomic, copy, readonly) NSURL *eventsServiceURL;

/// Config Service URL for the current region
@property (nonatomic, copy, readonly) NSURL *configServiceURL;

/// Reformed User-Agent String
@property (nonatomic, copy, readonly) NSString *userAgentString;

/// Legacy User-Agent String
@property (nonatomic, copy, readonly) NSString *legacyUserAgentString;

/// Unique Identifier for the client
@property (nonatomic, copy, readonly) NSString *clientId;

// MARK: - Location Collection

/// This property is only settable by the end user
@property (nonatomic, readonly) BOOL isCollectionEnabled;

/// This property is volatile
@property (nonatomic, readonly) BOOL isCollectionEnabledInSimulator;

// MARK: - Background Collection

/// Bool, is background collection enabled
@property (nonatomic, readonly) BOOL isCollectionEnabledInBackground;

/// Interval to wait before starting telemetry collection in the background
@property (nonatomic, readonly) NSTimeInterval backgroundStartupDelay;

/// Distance to set for the background collection geo-fence
@property (nonatomic, readonly) CLLocationDistance backgroundGeofence;

// MARK: - Certificate Pinning and Revocation

/// An array of revoked public key hashes
@property (nonatomic, copy, readonly) NSArray<NSString *>*certificateRevocationList;

/// The Certificate Pinning config
@property (nonatomic, copy, readonly) NSDictionary *certificatePinningConfig;

@end

NS_ASSUME_NONNULL_END
