#import <Foundation/Foundation.h>
#import "MMEEvent.h"

@class MMELocationManager;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventsManager : NSObject

+ (nullable instancetype)sharedManager;

@end

NS_ASSUME_NONNULL_END
