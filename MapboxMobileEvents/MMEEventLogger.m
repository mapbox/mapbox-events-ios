#import "MMEEventLogger.h"
#import "MMEEvent.h"
#import "MMEDate.h"
#import <WebKit/WebKit.h>

@implementation MMEEventLogger

+ (instancetype)sharedLogger {
    static MMEEventLogger *_sharedLogger;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[MMEEventLogger alloc] init];
    });
    
    return _sharedLogger;
}

#pragma mark -

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

