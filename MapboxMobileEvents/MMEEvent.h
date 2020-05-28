#import <Foundation/Foundation.h>
#import <MapboxMobileEvents/MMETypes.h>

NS_ASSUME_NONNULL_BEGIN

@class MMECommonEventData;
@class CLLocation;
@class CLVisit;

/// represents a telemetry event, with a name, date and attributes
@interface MMEEvent : NSObject <NSCopying,NSSecureCoding>

/// date on which the event occured - MMEEventKeyDateCreated
@property (nonatomic, readonly, copy) NSDate *date;

/// name of the event, from MMEConstants.h - MMEEventKeyEvent
@property (nonatomic, readonly, copy) NSString *name;

/// attributes of the event, a dictionary for which [NSJSONSerialization isValidJSONObject:] returns YES
@property (nonatomic, readonly, copy) NSDictionary *attributes;

// MARK: -

/*!
 @Brief Event Initializer
 @Discussion Initilization errors are reported to the EventsManagerDelegate if `error` is `nil`
 @param eventAttributes Dictionary of KeyValues representing the event
 @param error Error reference for init failure feedback
 @returns A new event
 */
- (instancetype)initWithAttributes:(NSDictionary *)eventAttributes error:(NSError **)error NS_DESIGNATED_INITIALIZER;

// MARK: - Generic Events

/*!
 @Brief Convenience Event Initializer
 @Discussion Initilization errors are reported to the EventsManagerDelegate if `error` is `nil`
 @param attributes Dictionary of KeyValues representing the event
 @returns A new event
 */
+ (instancetype)eventWithAttributes:(NSDictionary *)attributes;

/*!
 @Brief Convenience Event Initializer
 @Discussion Initilization errors are reported to the EventsManagerDelegate if `error` is `nil`
 @param attributes Dictionary of KeyValues representing the event
 @param error Error reference for init failure feedback
 @returns A new event
 */
+ (instancetype)eventWithAttributes:(NSDictionary *)attributes error:(NSError **)error;

// MARK: - Custom Events

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
/*!
 @Brief Error Event Initializer
 @param eventsError Error
 @param createError Initialization failure feedback reference
 @returns Initialized VisitEvent
 */
+ (instancetype)errorEventReporting:(NSError *)eventsError error:(NSError **)createError;

// MARK: - Deprecated

+ (instancetype)crashEventReporting:(NSError *)eventsError error:(NSError **)createError MME_DEPRECATED_GOTO("use errorEventReporting:error:", "-errorEventReporting:error:");

// MARK: - Debug Events

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes MME_DEPRECATED;
+ (instancetype)debugEventWithError:(NSError *)error MME_DEPRECATED;
+ (instancetype)debugEventWithException:(NSException *)except MME_DEPRECATED;

/*!
 @Brief Convenience MapLoad Event Iniitalizer
 @returns Initialized MapLoadEvent with inferred defaults
 */
+ (instancetype)mapLoadEvent;


/*!
 @Brief Convenience Map TapEvent Initializer
 @returns Initialized MapTapEvent with inferred platform defaults
 */
+(instancetype)mapTapEvent;


/*!
 @Brief Convenience MapDrag Event Initializer
 @returns Initialized MapDragEvent with implicit platform defaults
 */
+(instancetype)mapDragEndEvent;

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
