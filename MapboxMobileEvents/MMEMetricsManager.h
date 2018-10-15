#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetricsManager : NSObject

@property (nonatomic, readonly) int requests;
@property (nonatomic, readonly) int totalDataTransfer;
@property (nonatomic, readonly) int cellDataTransfer;
@property (nonatomic, readonly) int wifiDataTransfer;
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

- (void)countFromEventQueue:(NSArray *)eventQueue;
- (void)metricsFromEventQueue:(NSArray *)eventQueue;

@end

NS_ASSUME_NONNULL_END
