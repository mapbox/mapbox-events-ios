#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMEMetrics : NSObject

@property (nonatomic) NSUInteger requests;
@property (nonatomic) NSUInteger totalDataTransfer;
@property (nonatomic) NSUInteger cellDataTransfer;
@property (nonatomic) NSUInteger wifiDataTransfer;
@property (nonatomic) NSUInteger appWakeups;
@property (nonatomic) NSUInteger eventCountFailed;
@property (nonatomic) NSUInteger eventCountTotal;
@property (nonatomic) NSUInteger eventCountMax;
@property (nonatomic) NSInteger deviceTimeDrift;
@property (nonatomic) CLLocationDegrees deviceLat;
@property (nonatomic) CLLocationDegrees deviceLon;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *dateUTCString;
@property (nonatomic) NSDictionary *configResponseDict;
@property (nonatomic) NSMutableDictionary *eventCountPerType;
@property (nonatomic) NSMutableDictionary *failedRequestsDict;

@end

NS_ASSUME_NONNULL_END
