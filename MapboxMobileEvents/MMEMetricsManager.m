#import "MMEMetricsManager.h"
#import "MMEEvent.h"
#import "MMEReachability.h"
#import "MMEConstants.h"

@interface MMEMetricsManager ()

@property (nonatomic) int requests;
@property (nonatomic) long totalDataTransfer;
@property (nonatomic) long cellDataTransfer;
@property (nonatomic) long wifiDataTransfer;
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
            NSNumber *eventCount = [self.eventCountPerType objectForKey:event.name];
            eventCount = [NSNumber numberWithInteger:[eventCount integerValue] + 1];
            [self.eventCountPerType setObject:eventCount forKey:event.name];
        }
    }
}

- (void)metricsFromEvents:(nullable NSArray *)events andError:(nullable NSError *)error {
    if (error == nil) {
        self.requests = self.requests + 1;
    } else {
        if (events) {
            self.eventCountFailed = self.eventCountFailed + (int)events.count;
        }
        
        if ([error.userInfo objectForKey:MMEResponseKey]) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)[error.userInfo objectForKey:MMEResponseKey];
            NSString *urlString = [[response URL] absoluteString];
            NSNumber *statusCode = [NSNumber numberWithLong:(long)response.statusCode];
            NSString *statusCodeString = [statusCode stringValue];
            NSString *failedRequestKey = [NSString stringWithFormat:@"%@, %@",urlString, statusCodeString];
            
            if (self.failedRequestsDict == nil) {
                self.failedRequestsDict = [[NSMutableDictionary alloc] init];
            }
        
            NSNumber *failedCount = [self.failedRequestsDict objectForKey:failedRequestKey];
            failedCount = [NSNumber numberWithInteger:[failedCount integerValue] + 1];
            [self.failedRequestsDict setObject:failedCount forKey:failedRequestKey];
        }
    }
}

- (void)metricsFromData:(NSData *)data {
    self.totalDataTransfer = self.totalDataTransfer + data.length;
    
    if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
        self.wifiDataTransfer = self.wifiDataTransfer + data.length;
    } else {
        self.cellDataTransfer = self.cellDataTransfer + data.length;
    }
}

- (void)incrementAppWakeUpCount {
    self.appWakeups = self.appWakeups + 1;
}


@end
