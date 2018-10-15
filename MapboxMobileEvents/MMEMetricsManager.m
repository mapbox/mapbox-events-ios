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

- (void)metricsFromEvents:(nullable NSArray *)events andError:(nullable NSError *)error {
    if (error == nil) {
        if (self.requests == 0) {
            self.requests = 1;
        } else {
            self.requests = self.requests + 1;
        }
    } else {
        if (events) {
            if (self.eventCountFailed == 0) {
                self.eventCountFailed = (int)events.count;
            } else {
                self.eventCountFailed = self.eventCountFailed + (int)events.count;
            }
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
            
            if ([self.failedRequestsDict objectForKey:failedRequestKey] != nil) {
                NSNumber *failedCount = [self.failedRequestsDict objectForKey:failedRequestKey];
                failedCount = [NSNumber numberWithInteger:[failedCount integerValue] + 1];
                [self.failedRequestsDict setObject:failedCount forKey:failedRequestKey];
            } else {
                [self.failedRequestsDict setObject:@1 forKey:failedRequestKey];
            }
        }
    }
}

- (void)metricsFromData:(NSData *)data {
    if (self.totalDataTransfer == 0) {
        self.totalDataTransfer = data.length;
    } else {
        self.totalDataTransfer = self.totalDataTransfer + data.length;
    }
    
    if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
        if (self.wifiDataTransfer == 0) {
            self.wifiDataTransfer = data.length;
        } else {
            self.wifiDataTransfer = self.wifiDataTransfer + data.length;
        }
    } else {
        if (self.totalDataTransfer == 0) {
            self.cellDataTransfer = data.length;
        } else {
            self.cellDataTransfer = self.cellDataTransfer + data.length;
        }
    }
}


@end
