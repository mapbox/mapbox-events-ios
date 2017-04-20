#import <Foundation/Foundation.h>

@protocol MMEUniqueIdentifer <NSObject>

- (NSString *)rollingInstanceIdentifer;

@end

@interface MMEUniqueIdentifier : NSObject <MMEUniqueIdentifer>

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval;

- (NSString *)rollingInstanceIdentifer;

@end
