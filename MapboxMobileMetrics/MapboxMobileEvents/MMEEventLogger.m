#import "MMEEventLogger.h"

@implementation MMEEventLogger

+ (void)logEvent:(MMEEvent *)event {
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MGLMapboxMetricsDebugLoggingEnabled"]) {
        return;
    }
    
    NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry event %@", event]);
}

@end
