#import "NSDateFormatter+MMEMobileEvents.h"

@implementation NSDateFormatter (MMEMobileEvents)

+ (instancetype)rfc3339DateFormatter {
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    [NSTimeZone resetSystemTimeZone];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone systemTimeZone]];

    return rfc3339DateFormatter;
}

@end
