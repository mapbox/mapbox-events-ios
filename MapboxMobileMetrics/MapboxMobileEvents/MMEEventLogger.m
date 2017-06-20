#import "MMEEventLogger.h"

@implementation MMEEventLogger

+ (void)logEvent:(MMEEvent *)event {
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MMEMapboxMetricsDebugLoggingEnabled"]) {
        return;
    }
    
    NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry event %@", event]);
}

@end
