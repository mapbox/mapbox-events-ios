#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define MGL_EXPORT __attribute__((visibility ("default")))

@interface MMEEventsConfiguration : NSObject

@property (nonatomic) NSUInteger eventFlushCountThreshold;
@property (nonatomic) NSUInteger eventFlushSecondsThreshold;
@property (nonatomic) NSTimeInterval initializationDelay;
@property (nonatomic) NSTimeInterval instanceIdentifierRotationTimeInterval;
@property (nonatomic) CLLocationDistance locationManagerHibernationRadius;

+ (instancetype)configuration;

@end
