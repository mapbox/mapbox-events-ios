@import Foundation;

#import <MapboxMobileEvents/MMETypes.h>
#import "MMEEventConfigProviding.h"

NS_ASSUME_NONNULL_BEGIN

@class MMECommonEventData;
@class CLLocation;

/// represents a telemetry event, with a name, date and attributes
@interface MMEEvent : NSObject <NSCopying,NSSecureCoding>

/// date on which the event occured - MMEEventKeyDateCreated
@property (nonatomic, readonly, copy) NSDate *date;

/// name of the event, from MMEConstants.h - MMEEventKeyEvent
@property (nonatomic, readonly, copy) NSString *name;

/// attributes of the event, a dictionary for which [NSJSONSerialization isValidJSONObject:] returns YES
@property (nonatomic, readonly, copy) NSDictionary *attributes;

// MARK: -

/**
  Create a new Event

  Designated Initilizer
  
  - Parameters:
    - eventAttributes: attributes of the event
    - error: present if the event could not be created with the properties provided
    
  - Returns: a new event with the date, name and attributes provided
*/
- (instancetype)initWithAttributes:(NSDictionary *)eventAttributes error:(NSError **)error NS_DESIGNATED_INITIALIZER;

// MARK: - Generic Events

/**
  Create a new Event
  
  Initilization errors are reported to the EventsManagerDelegate
  
  - Parameter attributes: attrs
  
  - Returns: a new event
*/
+ (instancetype)eventWithAttributes:(NSDictionary *)attributes;

/**
  Create a new Event

  Initilization errors are reported to the EventsManagerDelegate if `error` is `nil`

  - Paramaters:
    - attributes: attrs
    - error: present if the event could not be created with the properties provided

  - Returns: a new event
*/
+ (instancetype)eventWithAttributes:(NSDictionary *)attributes error:(NSError **)error;

// MARK: - Custom Events

/*!
 @Brief Convenience initializer for TurnstileEvent
 @param config SDK state provoding model
 @param skuID Active SKU Identifier to add to event
 @param error Error Reference for feedback on any missing requirements to initialize
 */
+ (nullable instancetype)turnstileEventWithConfiguration:(id <MMEEventConfigProviding>)config
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

/*!
 @Brief VisitEvent Initializer
 @param visit CLVisit Event
 @returns Initialized VisitEvent
*/
+ (instancetype)visitEventWithVisit:(CLVisit*)visit;

// MARK: - Crash Events

/**
  Create a new error report
  
  - Parameters:
    - eventsError: error to report
    - createError: pointer to an error creating the report
    
  - Returns: a new error event
*/
+ (instancetype)errorEventReporting:(NSError *)eventsError error:(NSError **)createError;

// MARK: - Deprecated

+ (instancetype)crashEventReporting:(NSError *)eventsError error:(NSError **)createError MME_DEPRECATED_GOTO("use errorEventReporting:error:", "-errorEventReporting:error:");

// MARK: - Debug Events

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes MME_DEPRECATED;
+ (instancetype)debugEventWithError:(NSError *)error MME_DEPRECATED;
+ (instancetype)debugEventWithException:(NSException *)except MME_DEPRECATED;

// MARK: - Strong Event Models via Convenience Initializers

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
 @Brief Convenience MapLoad Event Iniitalizer
 @returns Initialized MapLoadEvent with inferred defaults
 */
+ (instancetype)mapLoadEvent;

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
 @Brief Convenience Map TapEvent Initializer
 @returns Initialized MapTapEvent with inferred platform defaults
 */
+(instancetype)mapTapEvent;

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

/*!
 @Brief Convenience MapDrag Event Initializer
 @returns Initialized MapDragEvent with implicit platform defaults
 */
+(instancetype)mapDragEndEvent;

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

/*!
 @Brief Convenience Locadtion Event Initializer
 @param identifier Session Identifier
 @returns Initialized LocationEvent
 */
+ (instancetype)locationEventWithID:(NSString*)identifier
                           location:(CLLocation*)location;

// MARK: - Deprecated (MMECommonEventData)

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(nullable MMECommonEventData *)commonEventData
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)mapLoadEventWithDateString:(NSString *)dateString commonEventData:(nullable MMECommonEventData *)commonEventData
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

// MARK: - Deprecated (Event Name)

+ (instancetype)eventWithName:(NSString *)eventName attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)navigationEventWithName:(NSString *)name attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)visionEventWithName:(NSString *)name attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)searchEventWithName:(NSString *)name attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)carplayEventWithName:(NSString *)name attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

// MARK: - Deprecated (Date String)

+ (instancetype)telemetryMetricsEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)mapTapEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes
    MME_DEPRECATED_MSG("map gesture events are no longer supported");

+ (instancetype)mapDragEndEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes
    MME_DEPRECATED_MSG("map gesture events are no longer supported");

+ (instancetype)mapOfflineDownloadStartEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)mapOfflineDownloadEndEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

+ (instancetype)eventWithDateString:(NSString *)dateString name:(NSString *)name attributes:(NSDictionary *)attributes
    MME_DEPRECATED_GOTO("use eventWithAttributes:error:", "-eventWithAttributes:error:");

@end

// MARK: - Deprecated Class

@interface MMECommonEventData : NSObject
@end


NS_ASSUME_NONNULL_END
