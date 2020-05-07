#import "MMEAPIClientBlockCounter.h"

@implementation MMEAPIClientBlockCounter

- (instancetype)init {
    if (self = [super init]) {
        _onErrors = @[].mutableCopy;
        _onBytesReceived = @[].mutableCopy;
        _eventQueue = @[].mutableCopy;
        _eventCount = @[].mutableCopy;
        _generateTelemetry = 0;
        _logEvents = @[].mutableCopy;
    }
    return self;
}

@end
