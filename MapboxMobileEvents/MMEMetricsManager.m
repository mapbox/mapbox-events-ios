#import "MMEMetricsManager.h"
#import "MMEEvent.h"
#import "MMEReachability.h"
#import "MMEConstants.h"

@interface MMEMetricsManager ()

@property (nonatomic) MMEMetrics *metrics;

@end

@implementation MMEMetricsManager

+ (instancetype)sharedManager {
    static MMEMetricsManager *_sharedManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[MMEMetricsManager alloc] init];
        _sharedManager.metrics = [[MMEMetrics alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _metrics = [[MMEMetrics alloc] init];
    }
    return self;
}

- (void)metricsFromEventQueue:(NSArray *)eventQueue {
    if (self.metrics.dateUTC == nil) {
        [self updateDateUTC];
    }
    
    if (eventQueue.count > 0) {
        if (self.metrics.eventCountPerType == nil) {
            self.metrics.eventCountPerType = [[NSMutableDictionary alloc] init];
        }
        
        self.metrics.eventCountTotal += (int)eventQueue.count;
        
        for (MMEEvent *event in eventQueue) {
            NSNumber *eventCount = [self.metrics.eventCountPerType objectForKey:event.name];
            eventCount = [NSNumber numberWithInteger:[eventCount integerValue] + 1];
            [self.metrics.eventCountPerType setObject:eventCount forKey:event.name];
        }
    }
}

- (void)metricsFromEvents:(nullable NSArray *)events error:(nullable NSError *)error {
    if (error == nil) {
        self.metrics.requests++;
    } else {
        if (events) {
            self.metrics.eventCountFailed += (int)events.count;
        }
        
        if ([error.userInfo objectForKey:MMEResponseKey]) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)[error.userInfo objectForKey:MMEResponseKey];
            NSString *urlString = response.URL.absoluteString;
            NSNumber *statusCode = @(response.statusCode);
            NSString *statusCodeString = [statusCode stringValue];
            NSString *failedRequestKey = [NSString stringWithFormat:@"%@, %@",urlString, statusCodeString];
            
            if (self.metrics.failedRequestsDict == nil) {
                self.metrics.failedRequestsDict = [[NSMutableDictionary alloc] init];
            }
        
            NSNumber *failedCount = [self.metrics.failedRequestsDict objectForKey:failedRequestKey];
            failedCount = [NSNumber numberWithInteger:[failedCount integerValue] + 1];
            [self.metrics.failedRequestsDict setObject:failedCount forKey:failedRequestKey];
        }
    }
}

- (void)metricsFromData:(NSData *)data {
    self.metrics.totalDataTransfer += data.length;
    
    if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
        self.metrics.wifiDataTransfer += data.length;
    } else {
        self.metrics.cellDataTransfer += data.length;
    }
}

- (void)incrementAppWakeUpCount {
    self.metrics.appWakeups++;
}

- (void)captureConfigurationJSON:(NSDictionary *)configuration {
    if (configuration) {
        self.metrics.configResponseDict = configuration;
    }
}

- (void)captureCoordinate:(CLLocationCoordinate2D)coordinate; {
    if (!self.metrics.deviceLat || !self.metrics.deviceLon) {
        self.metrics.deviceLat = round(coordinate.latitude*1000)/1000;
        self.metrics.deviceLon = round(coordinate.longitude*1000)/1000;
    }
}

- (void)updateDateUTC {
    self.metrics.dateUTC = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.metrics.dateUTCString = [dateFormatter stringFromDate:self.metrics.dateUTC];
}

- (void)resetMetrics {
    self.metrics = [[MMEMetrics alloc] init];
    [self updateDateUTC];
}

#pragma mark -- attributes

- (NSDictionary *)attributes {
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    attributes[MMEEventFailedRequests] = [NSString stringWithFormat:@"%@",self.metrics.failedRequestsDict];
    attributes[MMEEventEventCountPerType] = [NSString stringWithFormat:@"%@",self.metrics.eventCountPerType];
    attributes[MMEEventTotalDataTransfer] = @(self.metrics.totalDataTransfer);
    attributes[MMEEventCellDataTransfer] = @(self.metrics.cellDataTransfer);
    attributes[MMEEventWiFiDataTransfer] = @(self.metrics.wifiDataTransfer);
    attributes[MMEEventEventCountFailed] = @(self.metrics.eventCountFailed);
    attributes[MMEEventEventCountTotal] = @(self.metrics.eventCountTotal);
    attributes[MMEEventEventCountMax] = @(self.metrics.eventCountMax);
    attributes[MMEEventAppWakeups] = @(self.metrics.appWakeups);
    if (self.metrics.deviceLat != 0 && self.metrics.deviceLon != 0) {
        attributes[MMEEventDeviceLat] = @(self.metrics.deviceLat);
        attributes[MMEEventDeviceLon] = @(self.metrics.deviceLon);
    }
    attributes[MMEEventRequests] = @(self.metrics.requests);
    
    return attributes;
}

@end
