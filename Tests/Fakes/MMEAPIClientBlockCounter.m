#import "MMEAPIClientBlockCounter.h"

@implementation MMEAPIClientBlockCounter

- (instancetype)init {
    if (self = [super init]) {
        self.onSerializationErrors = @[].mutableCopy;
        self.onURLResponses = @[].mutableCopy;
        self.eventQueue = @[].mutableCopy;
        self.eventCount = @[].mutableCopy;
        self.generateTelemetry = 0;
    }
    return self;
}

@end
