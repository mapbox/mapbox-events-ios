#import "MMEUniqueIdentifier.h"

@interface MMEUniqueIdentifier ()

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic) NSDate *instanceIDRotationDate;
@property (nonatomic) NSString *instanceID;

@end

@implementation MMEUniqueIdentifier

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        _timeInterval = timeInterval;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString *)rollingInstanceIdentifer {
    [self.lock lock];
    if (self.instanceIDRotationDate && [[NSDate date] timeIntervalSinceDate:self.instanceIDRotationDate] >= 0) {
        _instanceID = nil;
    }
    if (!_instanceID) {
        _instanceID = [[NSUUID UUID] UUIDString];
        self.instanceIDRotationDate = [[NSDate date] dateByAddingTimeInterval:self.timeInterval];
    }
    NSString *instanceID = _instanceID;
    [self.lock unlock];
    return instanceID;
}

@end
