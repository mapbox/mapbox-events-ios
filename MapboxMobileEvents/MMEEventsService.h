#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MMEEventsConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventsService : NSObject

@property (nonatomic) MMEEventsConfiguration *configuration;

+ (instancetype)sharedService;

@end

NS_ASSUME_NONNULL_END
