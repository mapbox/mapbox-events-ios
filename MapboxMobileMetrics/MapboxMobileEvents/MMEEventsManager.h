#import <Foundation/Foundation.h>

@class MMELocationManager;

@interface MMEEventsManager : NSObject

@property (nonatomic, readonly) MMELocationManager *locationManager;

+ (nullable instancetype)sharedManager;

@end
