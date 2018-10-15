#import "MMEMetricsManager.h"
#import "MMEEvent.h"

@interface MMEMetricsManager ()

@property (nonatomic) int requests;
@property (nonatomic) int totalDataTransfer;
@property (nonatomic) int cellDataTransfer;
@property (nonatomic) int wifiDataTransfer;
@property (nonatomic) int appWakeups;
@property (nonatomic) int eventCountFailed;
@property (nonatomic) int eventCountTotal;
@property (nonatomic) int eventCountMax;
@property (nonatomic) int deviceTimeDrift;
@property (nonatomic) float deviceLat;
@property (nonatomic) float deviceLon;
@property (nonatomic) NSDate *dateUTC;
@property (nonatomic) NSDictionary *configResponseDict;
@property (nonatomic) NSMutableDictionary *eventCountPerType;
@property (nonatomic) NSMutableDictionary *failedRequestsDict;

@end

@implementation MMEMetricsManager

+ (instancetype)sharedManager {
    static MMEMetricsManager *_sharedManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[MMEMetricsManager alloc] init];
    });
    
    return _sharedManager;
}

- (void)metricsFromEventQueue:(NSArray *)eventQueue {
    if (eventQueue.count > 0) {
        if (self.eventCountPerType == nil) {
            self.eventCountPerType = [[NSMutableDictionary alloc] init];
        }
        
        self.eventCountTotal = self.eventCountTotal + (int)eventQueue.count;
        
        for (MMEEvent *event in eventQueue) {
            if ([self.eventCountPerType objectForKey:event.name] != nil) {
                NSNumber *eventCount = [self.eventCountPerType objectForKey:event.name];
                eventCount = [NSNumber numberWithInteger:[eventCount integerValue] + 1];
                [self.eventCountPerType setObject:eventCount forKey:event.name];
            } else {
                [self.eventCountPerType setObject:@1 forKey:event.name];
            }
        }
    }
}



@end
