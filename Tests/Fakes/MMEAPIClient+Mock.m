#import "MMEAPIClient+Mock.h"
#import "MMEMockEventConfig.h"

@implementation MMEAPIClient (Mock)

+(MMEAPIClient*)clientWithMockConfig {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    return [[MMEAPIClient alloc] initWithConfig:config
                                 onError:^(NSError * _Nonnull error) {}
                         onBytesReceived:^(NSUInteger bytes) {}
                      onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {}
                      onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {}
                onGenerateTelemetryEvent:^{}
                                     onLogEvent:^(MMEEvent * _Nonnull event) {}];
    
}
@end
