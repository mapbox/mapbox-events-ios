#import "MMEEventLogger.h"
#import "MMEEvent.h"
#import "MMEDate.h"

@implementation MMEEventLogger

+ (instancetype)sharedLogger {
    static MMEEventLogger *_sharedLogger;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[MMEEventLogger alloc] init];
        [_sharedLogger setHandler:nil];
    });
    
    return _sharedLogger;
}

- (void)setHandler:(void (^)(NSUInteger, NSString *, NSString *))handler {
    if (!handler) {
        _handler = [self defaultBlockHandler];
    } else {
        _handler = handler;
    }
}

#pragma mark -

- (void)logEvent:(MMEEvent *)event {
    if (self.isEnabled) {
        self.handler(MMELogEvent, event.name, [NSString stringWithFormat:@"%@",event.attributes]);
    }
}

- (void)logPriority:(NSUInteger)priority withType:(NSString *)type andMessage:(NSString *)message {
    if (self.isEnabled) {
        self.handler(priority, type, message);
    }
}

- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes {
    MMEMutableMapboxEventAttributes *combinedAttributes = [MMEMutableMapboxEventAttributes dictionaryWithDictionary:attributes];
    [combinedAttributes setObject:[MMEDate.iso8601DateFormatter stringFromDate:[NSDate date]] forKey:@"created"];
    MMEEvent *debugEvent = [MMEEvent debugEventWithAttributes:combinedAttributes];
    [MMEEventLogger.sharedLogger logEvent:debugEvent];
}

- (MMELoggingBlockHandler)defaultBlockHandler {
    MMELoggingBlockHandler mapboxHandler = ^(NSUInteger priority, NSString *type, NSString *message) {
        NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry Log Message: %@\nType: %@\nPriority: %lu", message, type, (unsigned long)priority]);
    };
 
    return mapboxHandler;
}

@end
