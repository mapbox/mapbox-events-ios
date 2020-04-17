@import Foundation;

#import <MapboxMobileEvents/MMETypes.h>

NS_ASSUME_NONNULL_BEGIN

@class MMECommonEventData;

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

/**
  Create a new Turnstile Event

  - Parameter attributes: event attrs
  
  - Returns:  a new turnstile event
*/
+ (instancetype)turnstileEventWithAttributes:(NSDictionary *)attributes;

/**
  Create a new Visit Event

  - Parameter attributes: event attrs
  
  - Returns: a new visit event
*/
+ (instancetype)visitEventWithAttributes:(NSDictionary *)attributes;

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
