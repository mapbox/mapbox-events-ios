#import "MMEMetricsManager.h"
#import "MMEReachability.h"
#import "MMEConstants.h"
#import "MMENSDateWrapper.h"
#import "MMEEventLogger.h"

@interface MMEMetricsManager ()

@property (nonatomic) MMEMetrics *metrics;
@property (nonatomic) MMENSDateWrapper *dateWrapper;

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

- (instancetype)init {
    self = [super init];
    if (self) {
        _metrics = [[MMEMetrics alloc] init];
        _dateWrapper = [[MMENSDateWrapper alloc] init];
    }
    return self;
}

- (void)updateMetricsFromEventQueue:(NSArray *)eventQueue {
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

- (void)updateMetricsFromEvents:(nullable NSArray *)events request:(NSURLRequest *)request error:(nullable NSError *)error {
    if (request.HTTPBody && error == nil) {
        [self updateMetricsFromData:request.HTTPBody];
    }
    
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

- (void)updateMetricsFromData:(NSData *)data {
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

- (void)updateConfigurationJSON:(NSDictionary *)configuration {
    if (configuration) {
        self.metrics.configResponseDict = configuration;
    }
}

- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate; {
    if (!self.metrics.deviceLat || !self.metrics.deviceLon) {
        self.metrics.deviceLat = round(coordinate.latitude*1000)/1000;
        self.metrics.deviceLon = round(coordinate.longitude*1000)/1000;
    }
}

- (void)formatUTCDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:utcTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.metrics.dateUTCString = [dateFormatter stringFromDate:date];
}

- (void)resetMetrics {
    self.metrics = [[MMEMetrics alloc] init];
}

#pragma mark -- Event creation

- (NSDictionary *)attributes {
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (self.metrics.date) {
        [self formatUTCDate:self.metrics.date];
        attributes[MMEEventDateUTC] = self.metrics.dateUTCString;
    }
    attributes[MMEEventFailedRequests] = [NSString stringWithFormat:@"%@",self.metrics.failedRequestsDict];
    attributes[MMEEventEventCountPerType] = [NSString stringWithFormat:@"%@",self.metrics.eventCountPerType];
    attributes[MMEEventConfigResponse] = [NSString stringWithFormat:@"%@",self.metrics.configResponseDict];
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
    attributes[MMEEventDeviceTimeDrift] = @(self.metrics.deviceTimeDrift);
    
    return attributes;
}

- (MMEEvent *)generateTelemetryMetricsEvent {
    if (self.metrics.date && [self.metrics.date timeIntervalSinceDate:[self.dateWrapper startOfTomorrowFromDate:self.metrics.date]] < 0) {
        NSString *debugDescription = [NSString stringWithFormat:@"TelemetryMetrics event isn't ready to be sent; waiting until %@ to send", [self.dateWrapper startOfTomorrowFromDate:self.metrics.date]];
        [self pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeTelemetryMetrics,
                                             MMEEventKeyLocalDebugDescription: debugDescription}];
        return nil;
    }
    
    MMEEvent *telemetryMetrics = [MMEEvent telemetryMetricsEventWithDateString:[self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]] attributes:[self attributes]];
    [MMEEventLogger.sharedLogger logEvent:telemetryMetrics];
    
    return telemetryMetrics;
}

- (void)pushDebugEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    [combinedAttributes setObject:[self.dateWrapper formattedDateStringForDate:[self.dateWrapper date]] forKey:@"created"];
    MMEEvent *debugEvent = [MMEEvent debugEventWithAttributes:attributes];
    [[MMEEventLogger sharedLogger] logEvent:debugEvent];
}

@end
