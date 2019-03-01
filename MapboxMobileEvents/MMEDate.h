#import <Foundation/Foundation.h>

/*!
@brief MMEDate is a subclas of NSDate which stores information needed to compute clock offsets from servers
*/
@interface MMEDate : NSDate <NSSecureCoding>
/*! @biref store the recorded time offset for the date when created using the +[MMEDate date] or +[MMEDate dateWithOffsetFromServer:(NSTimeInterval)offset]` methods */
@property(nonatomic,assign,readonly) NSTimeInterval offsetFromServer;

/*! @brief computes, reccords and returns the time offset from the server's time frame */
+ (NSTimeInterval)recordTimeOffsetFromServer:(NSDate *)responseDate;

/*! @brief returns the recorded time offset from the server's time frame */
+ (NSTimeInterval)recordedTimeOffsetFromServer;

/*! @brief static date formatter */
+ (NSDateFormatter *)iso8601DateFormatter;

/*! @brief returns a date with the recordedTimeOffsetFromServer */
+ (MMEDate *)dateWithRecordedOffset;

/*! @brief returns a date with the specified timeOffsetFromServer */
+ (MMEDate *)dateWithOffset:(NSTimeInterval)serverTimeFrame;

#pragma mark -

- (MMEDate *)initWithOffset:(NSTimeInterval)serverTimeFrame;

#pragma mark -

/*! @brief returns the date, with the offsetFromServer adjustment applied, putting the date in the server's time frame  */
- (NSDate*) offsetToServer;

@end

#pragma mark -

@interface NSDate (MMEDate)

- (NSDate *)mme_oneDayLater; // --> (instanctype) startOfTomorrow;

@end
