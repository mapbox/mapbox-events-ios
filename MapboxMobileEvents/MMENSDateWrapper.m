#import "MMENSDateWrapper.h"

@interface MMENSDateWrapper ()

@property (nonatomic) NSDateFormatter *iso8601DateFormatter;

@end

@implementation MMENSDateWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _iso8601DateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [_iso8601DateFormatter setLocale:enUSPOSIXLocale];
        [_iso8601DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        [_iso8601DateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return self;
}

- (NSDate *)date {
    return [NSDate date];
}

- (NSString *)formattedDateStringForDate:(NSDate *)date {
    return [self.iso8601DateFormatter stringFromDate:date];
}

- (NSDate *)startOfTomorrow {
    // Find the time a day from now (sometime tomorrow)
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    NSDate *sometimeTomorrow = [calendar dateByAddingComponents:dayComponent toDate:[self date] options:0];
    
    NSDate *startOfTomorrow = nil;
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&startOfTomorrow interval:nil forDate:sometimeTomorrow];
    return startOfTomorrow;
}

@end
