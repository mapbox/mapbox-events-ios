#import <Foundation/Foundation.h>

@interface MMENSDateWrapper : NSObject

- (NSDate *)date;
- (NSString *)formattedDateStringForDate:(NSDate *)date;
- (NSDate *)startOfTomorrow;

@end
