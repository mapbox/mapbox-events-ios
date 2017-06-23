#import "MMEEventLogger.h"

@implementation MMEEventLogger

static BOOL _enabled;

+ (void)logEvent:(MMEEvent *)event {    
    if (_enabled) {
        NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry event %@", event]);
    }
}

+ (BOOL)isEnabled {
    return _enabled;
}

+ (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
}

@end
