#import "MMELogger.h"
#import "MMEEvent.h"
#import "MMEDate.h"

@implementation MMELogger

+ (instancetype)sharedLogger {
    static MMELogger *_sharedLogger;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedLogger = [[MMELogger alloc] init];
    });

    return _sharedLogger;
}

+ (NSString *)logLevelString:(MMELogLevel)level {
    NSString *levelString = @"Unknown";
    
    switch (level) {
        case MMELogNone:    levelString = @"NONE";      break;
        case MMELogFatal:   levelString = @"FATAL";     break;
        case MMELogError:   levelString = @"ERROR";     break;
        case MMELogWarn:    levelString = @"WARN";      break;
        case MMELogInfo:    levelString = @"Info";      break;
        case MMELogEvent:   levelString = @"Event";     break;
        case MMELogNetwork: levelString = @"Network";   break;
        case MMELogDebug:   levelString = @"Debug";     break;
    }
    
    return levelString;
}

+ (MMELoggingBlockHandler)defaultBlockHandler {
    MMELoggingBlockHandler mapboxHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        NSLog(@"%@", [NSString stringWithFormat:@"%@ %@ %@: %@",
            NSStringFromClass(self), [MMELogger logLevelString:level], type, message]);
    };
 
    return mapboxHandler;
}

// MARK: -

- (instancetype)init {
    if ((self = [super init])) {
#if DEBUG
        self.level = MMELogInfo;
#else
        self.level = MMELogFatal;
#endif
        self.handler = nil;
    }
    return self;
}


// MARK: - Properties
 
- (void)setHandler:(void (^)(MMELogLevel, NSString *, NSString *))handler {
    if (!handler) {
        _handler = MMELogger.defaultBlockHandler;
    } else {
        _handler = handler;
    }
}

// MARK: -

- (void)logEvent:(MMEEvent *)event {
    if (self.isEnabled) {
        self.handler(MMELogEvent, event.name, [NSString stringWithFormat:@"%@",event.attributes]);
    }
}

- (void)logPriority:(MMELogLevel)priority withType:(NSString *)type andMessage:(NSString *)message {
    if (self.isEnabled && (self.level >= priority)) {
        self.handler(priority, type, message);
    }
}

- (void)pushDebugEventWithAttributes:(MMEMapboxEventAttributes *)attributes {
    MMEMutableMapboxEventAttributes *combinedAttributes = [MMEMutableMapboxEventAttributes dictionaryWithDictionary:attributes];
    [combinedAttributes setObject:[MMEDate.iso8601DateFormatter stringFromDate:[NSDate date]] forKey:@"created"];
    MMEEvent *debugEvent = [MMEEvent debugEventWithAttributes:combinedAttributes];
    [self logEvent:debugEvent];
}

@end
