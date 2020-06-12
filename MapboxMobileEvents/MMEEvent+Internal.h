#import "MMEEvent.h"

@protocol MMEConfigurationProviding;

NS_ASSUME_NONNULL_BEGIN

// MARK: - Strong Event Models via Convenience Initializers
@interface MMEEvent (Internal)

// MARK: - Map Events

/*!
 @brief Designated MapLoad Event Iniitalizer
 @param createdDate Created date
 @param vendorID Vendor ID
 @param deviceModel Device Model
 @param operatingSystem Operating System
 @param screenScale Screen Scale
 @param fontScale Font Scale
 @param deviceOrientation Device Orientation as a String
 @param isReachableViaWiFi Wifi Reachability status
 @returns Initialized MapLoadEvent
 */
+ (instancetype)mapLoadEventWithCreatedDate:(NSDate*)createdDate
                                   vendorID:(NSString*)vendorID
                                deviceModel:(NSString*)deviceModel
                            operatingSystem:(NSString*)operatingSystem
                                screenScale:(NSNumber*)screenScale
                                  fontScale:(nullable NSNumber*)fontScale
                          deviceOrientation:(nullable NSString*)deviceOrientation
                         isReachableViaWiFi:(BOOL)isReachableViaWiFi;


/*!
 @Brief Designated MapTapEvent Initializer
 @param createdDate Date event was created
 @param deviceOrientation Optional Device Orientation
 @param isReachableViaWiFi Wifi Reachability Status
 @returns Initialized MapTapEvent
 */
+(instancetype)mapTapEventWithCreatedDate:(NSDate*)createdDate
                        deviceOrientation:(nullable NSString*)deviceOrientation
                       isReachableViaWiFi:(BOOL)isReachableViaWiFi;

/*!
 @Brief Designtated MapDragEvent Initializer
 @param createdDate Date event was created
 @param deviceOrientation DeviceOrientation
 @param isReachableViaWiFi Wifi Reachability status
 @returns Initialized MapDragEvent
 */
+ (instancetype)mapDragEndEventWithCreatedDate:(NSDate*)createdDate
                             deviceOrientation:(nullable NSString*)deviceOrientation
                            isReachableViaWiFi:(BOOL)isReachableViaWiFi;


// MARK: - Location Event(s)

/*!
 @Brief Designated Locadtion Event Initializer
 @param identifier Session Identifier
 @param source Source of the reporting
 @param operatingSystem Operating System
 @param applicationState (Optional) UIApplicationState
 @returns Initialized LocationEvent
 */
+(instancetype)locationEventWithID:(NSString*)identifier
                          location:(CLLocation*)location
                            source:(NSString*)source
                   operatingSystem:(NSString*)operatingSystem
                  applicationState:(nullable NSString*)applicationState;

// MARK: - Turnstile Event

/*!
 @Brief Convenience initializer for TurnstileEvent
 @param config SDK state provoding model
 @param skuID Active SKU Identifier to add to event
 @param error Error Reference for feedback on any missing requirements to initialize
 */
+ (nullable instancetype)turnstileEventWithConfiguration:(id <MMEConfigurationProviding>)config
                                                   skuID:(nullable NSString*)skuID
                                                   error:(NSError**)error;


/*!
 @Brief Convenience initializer for TurnstileEvent
 @param createdDate Creation date for this event
 @param vendorID Vendor's ID
 @param deviceModel Device Model eg. iPhone Xs
 @param operatingSystem Operating System eg. iOS 13.2
 @param sdkIdentifier User Agent Base
 @param sdkVersion Host SDK Version
 @param isTelemetryEnabled TelemetryCollection Enable Status
 @param locationAuthorization Location authorization state
 @param skuID Active SKU Identifier to add to event
 */
+(instancetype)turnstileEventWithCreatedDate:(NSDate*)createdDate
                                    vendorID:(NSString*)vendorID
                                 deviceModel:(NSString*)deviceModel
                             operatingSystem:(NSString*)operatingSystem
                               sdkIdentifier:(NSString*)sdkIdentifier
                                  sdkVersion:(NSString*)sdkVersion
                          isTelemetryEnabled:(BOOL)isTelemetryEnabled
                     locationServicesEnabled:(BOOL)locationServicesEnabled
                       locationAuthorization:(NSString*)locationAuthorization
                                       skuID:(nullable NSString*)skuID;

@end

NS_ASSUME_NONNULL_END
