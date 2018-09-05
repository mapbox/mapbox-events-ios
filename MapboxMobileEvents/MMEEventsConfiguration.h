#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define MGL_EXPORT __attribute__((visibility ("default")))

@interface MMEEventsConfiguration : NSObject

@property (nonatomic) NSUInteger eventFlushCountThreshold;
@property (nonatomic) NSUInteger eventFlushSecondsThreshold;
@property (nonatomic) NSTimeInterval initializationDelay;
@property (nonatomic) NSTimeInterval instanceIdentifierRotationTimeInterval;
@property (nonatomic) NSTimeInterval configurationRotationTimeInterval;
@property (nonatomic) CLLocationDistance locationManagerHibernationRadius;
@property (nonatomic) NSArray *blacklist;

+ (instancetype)configuration;
+ (instancetype)configurationFromData:(NSData *)data;

@end
