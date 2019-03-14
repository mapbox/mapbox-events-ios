#import "MMEMetrics.h"

@implementation MMEMetrics

- (instancetype)init {
    self = [super init];
    if (self) {
        _failedRequestsDict = [[NSMutableDictionary alloc] init];
        _eventCountPerType = [[NSMutableDictionary alloc] init];
        _date = [NSDate date];
        _totalBytesSent = 0;
        _cellBytesSent = 0;
        _wifiBytesSent = 0;
        _totalBytesReceived = 0;
        _cellBytesReceived = 0;
        _wifiBytesReceived = 0;
        _eventCountFailed = 0;
        _eventCountTotal = 0;
        _eventCountMax = 0;
        _appWakeups = 0;
        _deviceLat = 0;
        _deviceLon = 0;
        _requests = 0;
    }
    return self;
}

- (void)computeTransferredBytes {
    _totalBytesSent = _cellBytesSent + _wifiBytesSent;
    _totalBytesReceived = _cellBytesReceived + _wifiBytesReceived;
}

@end
