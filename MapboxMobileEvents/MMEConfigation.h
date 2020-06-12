#import <Foundation/Foundation.h>
#import "MMEConfigurationProviding.h"
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@class MMEDate;
@class MMEConfig;

/*!
 @Brief Container of App Preferences as well as Remote Preferendes
 @Discussion MMEPreferences provides an interface to define default values, as well as provide support
    for loading values from Bundle plist, or loaded Remote Config.
 */
@interface MMEConfigation : NSObject <MMEConfigurationProviding>

// MARK: - Initializer

/**
 Initializer
 @param bundle Source of App provided configurations
 @param userDefaults DataStore Instance
 */
-(instancetype)initWithBundle:(NSBundle*)bundle
                    dataStore:(NSUserDefaults*)userDefaults;

// MARK: - Properties

/// Bundle Providing App Provided defaults
@property (nonatomic, strong, readonly) NSBundle* bundle;

/// DataStorage Instance for the values
@property (nonatomic, strong, readonly) NSUserDefaults* userDefaults;


/// Interval to wait before starting up when the application launches
@property (nonatomic, assign, readonly) NSTimeInterval startupDelay;

/// Number of events to put into a batch, the MMEEventsManager will flush it's queue at this threshold
@property (nonatomic, assign, readonly) NSUInteger eventFlushCount;

/// Maximum Time interval between event flush
@property (nonatomic, assign, readonly) NSTimeInterval eventFlushInterval;

/// Interval at which we rotate the unique identifier for this SDK instance
@property (nonatomic, assign, readonly) NSTimeInterval identifierRotationInterval;

/// Interval at which we check for updated configuration
@property (nonatomic, assign, readonly) NSTimeInterval configUpdateInterval;

/// Tag for events
@property (nullable, nonatomic, copy, readonly) NSString *eventTag;

// MARK: - Volatile Configuration

/// Access Token
@property (nullable, nonatomic, copy) NSString *accessToken;

/// User-Agent Base
@property (nullable, nonatomic, copy) NSString *legacyUserAgentBase;

/// Host SDK Version
@property (nullable, nonatomic, copy) NSString *legacyHostSDKVersion;

/// Unique Identifier for the client
@property (nonatomic, copy, readonly) NSString *clientId;

/// CN Region Setting
@property (nonatomic, assign) BOOL isChinaRegion;

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

// MARK: - Update Configuration

@property (nonatomic, nullable) MMEDate *configUpdateDate;

// MARK: - Location Collection

/// This property is only settable by the end user
@property (nonatomic, assign) BOOL isCollectionEnabled;

/// This property is volatile
@property (nonatomic, readonly) BOOL isCollectionEnabledInSimulator;

// MARK: - Background Collection

/// Bool, is background collection enabled (disabling isCollectionEnabled automatically disables collection in background)
@property (nonatomic, assign) BOOL isCollectionEnabledInBackground;

/// Interval to wait before starting telemetry collection in the background
@property (nonatomic, readonly) NSTimeInterval backgroundStartupDelay;

/// Distance to set for the background collection geo-fence
@property (nonatomic, readonly) CLLocationDistance backgroundGeofence;

// MARK: - Certificate Pinning and Revocation

/// An array of revoked public key hashes
@property (nonatomic, copy, readonly) NSArray<NSString *>*certificateRevocationList;

/// The Certificate Pinning config
@property (nonatomic, copy, readonly) NSDictionary *certificatePinningConfig;

/// Public Keys (For Cert Pinning) */
- (NSMutableArray<NSString*>*)comPublicKeys;

/// Public Keys (for China) (For Cert Pinning) */
- (NSMutableArray<NSString*>*)chinaPublicKeys;

// MARK: - Update

/*! Updates Preferences from Config*/
- (void)updateWithConfig:(MMEConfig*)config;

@end

NS_ASSUME_NONNULL_END
