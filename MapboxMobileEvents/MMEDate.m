#import "MMEDate.h"

static NSTimeInterval _timeOffsetFromServer = 0.0; // TODO maintain a list of MMEDates with offsets

@interface MMEDate ()
@property(nonatomic,assign) NSTimeInterval sinceReferenceDate;

@end

#pragma mark -

@implementation MMEDate

+ (NSTimeInterval) recordTimeOffsetFromServer:(NSDate *)responseDate {
    _timeOffsetFromServer = responseDate.timeIntervalSinceNow;

    return _timeOffsetFromServer;
}

+ (NSTimeInterval) recordedTimeOffsetFromServer {
    return _timeOffsetFromServer;
}

+ (NSDateFormatter *)iso8601DateFormatter {
    static NSDateFormatter *_iso8601DateFormatter;

    if (!_iso8601DateFormatter) {
        _iso8601DateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [_iso8601DateFormatter setLocale:enUSPOSIXLocale];
        [_iso8601DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        [_iso8601DateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }

    return _iso8601DateFormatter;
}

/*! @brief returns a date with the recordedTimeOffsetFromServer */
+ (MMEDate*) dateWithRecordedOffset {
    return [MMEDate dateWithOffset:[MMEDate recordedTimeOffsetFromServer]];
}

/*! @brief returns a date with the specified timeOffsetFromServer */
+ (MMEDate*) dateWithOffset:(NSTimeInterval)serverTimeFrame {
    return [[MMEDate alloc] initWithOffset:serverTimeFrame];
}

#pragma mark - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

#pragma mark -

- (MMEDate*) initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ti offset:(NSTimeInterval)serverTimeFrame {
    if (self = [super init]) {
        _sinceReferenceDate = ti;
        _offsetFromServer = serverTimeFrame;
    }

    return self;
}

- (MMEDate*) initWithOffset:(NSTimeInterval)serverTimeFrame {
    return [self initWithTimeIntervalSinceReferenceDate:[NSDate timeIntervalSinceReferenceDate] offset:serverTimeFrame];
}

#pragma mark - NSDate Overrides

- (instancetype)initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ti {
    return [self initWithTimeIntervalSinceReferenceDate:ti offset:[MMEDate recordedTimeOffsetFromServer]];
}

- (NSTimeInterval)timeIntervalSinceReferenceDate {
    return _sinceReferenceDate;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[MMEDate alloc] initWithTimeIntervalSinceReferenceDate:_sinceReferenceDate offset:_offsetFromServer];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _sinceReferenceDate = [aDecoder decodeDoubleForKey:@"sinceReferenceDate"];
        _offsetFromServer = [aDecoder decodeDoubleForKey:@"offsetFromServer"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:_sinceReferenceDate forKey:@"sinceReferenceDate"];
    [aCoder encodeDouble:_offsetFromServer forKey:@"offsetFromServer"];
    [aCoder encodeInteger:1 forKey:@"MMEDateVersion"];
}

#pragma mark - MMEDate Methods

- (MMEDate*) offsetToServer {
    return [self dateByAddingTimeInterval:_offsetFromServer]; // negative?
}

@end

#pragma mark -

@implementation NSDate (MMEDate)


- (NSDate *)mme_oneDayLater {
    // Find the time a day from now (sometime tomorrow)
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    NSDate *sometimeTomorrow = [calendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
    NSDate *startOfTomorrow = nil;
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&startOfTomorrow interval:nil forDate:sometimeTomorrow];
    return startOfTomorrow;
}

@end
