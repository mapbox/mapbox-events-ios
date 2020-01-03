#import <Foundation/Foundation.h>

/** MMEDate is a subclass of NSDate which stores information needed to compute clock offsets from servers */
@interface MMEDate : NSDate

/** store the recorded time offset for the date when created using the +[MMEDate date] or +[MMEDate dateWithOffsetFromServer:(NSTimeInterval)offset]` methods */
@property(nonatomic,assign,readonly) NSTimeInterval offsetFromServer;

/** computes, records and returns the time offset from the server's time frame */
+ (NSTimeInterval)recordTimeOffsetFromServer:(NSDate *)responseDate;

/** returns the recorded time offset from the server's time frame */
+ (NSTimeInterval)recordedTimeOffsetFromServer;

/** UTC yyyy-MM-dd'T'HH:mm:ss.SSSZ formatter */
+ (NSDateFormatter *)iso8601DateFormatter;

/** UTC yyyy-MM-dd formatter */
+ (NSDateFormatter *)iso8601DateOnlyFormatter;

/*! @biref HTTP-date formatter
    @link https://tools.ietf.org/html/rfc7231#section-7.1.1.1
*/
+ (NSDateFormatter *)HTTPDateFormatter;

/** returns a date with the recordedTimeOffsetFromServer */
+ (MMEDate *)dateWithRecordedOffset;

/** returns a date with the specified timeOffsetFromServer */
+ (MMEDate *)dateWithOffset:(NSTimeInterval)serverTimeFrame;

/** return an MMEDate with the time specified in the provided date */
+ (MMEDate *)dateWithDate:(NSDate *)date;

// MARK: -

- (MMEDate *)initWithOffset:(NSTimeInterval)serverTimeFrame;

// MARK: -

/** returns the date, with the offsetFromServer adjustment applied, putting the date in the server's time frame  */
- (NSDate *)offsetToServer;

@end

// MARK: -

@interface NSDate (MMEDate)

/** returns a date at 00:00:00 on the next calendar day */
- (NSDate *)mme_startOfTomorrow;

@end
