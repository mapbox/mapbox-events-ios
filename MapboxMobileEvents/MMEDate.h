#import <Foundation/Foundation.h>

/*!
@brief MMEDate is a subclas of NSDate which stores information needed to compute clock offsets from servers
*/
@interface MMEDate : NSDate <NSSecureCoding>

/*! @brief computes, reccords and returns the time offset from the server's concept of 'now' */
+ (NSTimeInterval)recordTimeOffsetFromServer:(NSDate *)responseDate;
+ (NSTimeInterval)recordedTimeOffsetFromServer;

/*! @brief static date formatter */
+ (NSDateFormatter *)iso8601DateFormatter;

@end

#pragma mark -

@interface NSDate (MMEDate)

- (NSDate *)mme_oneDayLater; // --> (instanctype) startOfTomorrow;

@end
