#import "MMEEventLogger.h"
#import "MMEEvent.h"
#import "MMEUINavigation.h"
#import "MMEDate.h"
#import <WebKit/WebKit.h>

@interface MMEEventLogger()

@property (nonatomic, copy) NSString *dateForDebugLogFile;
@property (nonatomic) dispatch_queue_t debugLogSerialQueue;
@property (nonatomic) NSDate *nextLogFileDate;
@property (nonatomic, getter=isTimeForNewLogFile) BOOL timeForNewLogFile;

@end

@implementation MMEEventLogger

+ (instancetype)sharedLogger {
    static MMEEventLogger *_sharedLogger;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[MMEEventLogger alloc] init];
    });
    
    return _sharedLogger;
}

+ (NSDateFormatter *)logFileDateFormatter {
    static NSDateFormatter *_logFileFormatter = nil;
    if (!_logFileFormatter) {
        _logFileFormatter = [[NSDateFormatter alloc] init];
        [_logFileFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
        [_logFileFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }

    return _logFileFormatter;
}

#pragma mark -

- (instancetype)init {
    self = [super init];
    if (self) {
        MMEDate* now = [MMEDate date];
        self.dateForDebugLogFile = [MMEEventLogger.logFileDateFormatter stringFromDate:now];
        self.nextLogFileDate = [now mme_startOfTomorrow];
    }
    return self;
}

- (void)logEvent:(MMEEvent *)event {
    if (self.isEnabled) {
        NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry event %@", event]);
    }
}

- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes {
    MMEMutableMapboxEventAttributes *combinedAttributes = [MMEMutableMapboxEventAttributes dictionaryWithDictionary:attributes];
    [combinedAttributes setObject:[MMEDate.iso8601DateFormatter stringFromDate:[NSDate date]] forKey:@"created"];
    MMEEvent *debugEvent = [MMEEvent debugEventWithAttributes:combinedAttributes];
    [MMEEventLogger.sharedLogger logEvent:debugEvent];
}

@end

