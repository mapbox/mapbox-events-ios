#import "MMEMetrics.h"

@implementation MMEMetrics

- (instancetype)init {
    self = [super init];
    if (self) {
        self.failedRequestsDict = [[NSMutableDictionary alloc] init];
        self.eventCountPerType = [[NSMutableDictionary alloc] init];
        self.date = [NSDate date];
        self.totalDataTransfer = 0;
        self.cellDataTransfer = 0;
        self.wifiDataTransfer = 0;
        self.eventCountFailed = 0;
        self.eventCountTotal = 0;
        self.eventCountMax = 0;
        self.appWakeups = 0;
        self.deviceLat = 0;
        self.deviceLon = 0;
        self.requests = 0;
    }
    return self;
}

@end
