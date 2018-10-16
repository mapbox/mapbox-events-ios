#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetricsManager : NSObject

@property (nonatomic, readonly) int requests;
@property (nonatomic, readonly) long totalDataTransfer;
@property (nonatomic, readonly) long cellDataTransfer;
@property (nonatomic, readonly) long wifiDataTransfer;
@property (nonatomic, readonly) int appWakeups;
@property (nonatomic, readonly) int eventCountFailed;
@property (nonatomic, readonly) int eventCountTotal;
@property (nonatomic, readonly) int eventCountMax;
@property (nonatomic, readonly) int deviceTimeDrift;
@property (nonatomic, readonly) float deviceLat;
@property (nonatomic, readonly) float deviceLon;
@property (nonatomic, readonly) NSDate *dateUTC;
@property (nonatomic, readonly) NSDictionary *configResponseDict;
@property (nonatomic, readonly) NSMutableDictionary *eventCountPerType;
@property (nonatomic, readonly) NSMutableDictionary *failedRequestsDict;

+ (instancetype)sharedManager;

- (void)metricsFromData:(NSData *)data;
- (void)metricsFromEventQueue:(NSArray *)eventQueue;
- (void)metricsFromEvents:(nullable NSArray *)events andError:(nullable NSError *)error;
- (void)incrementAppWakeUpCount;

@end

NS_ASSUME_NONNULL_END
