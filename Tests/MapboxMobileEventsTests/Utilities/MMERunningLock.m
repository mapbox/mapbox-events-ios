#import "MMERunningLock.h"

@implementation MMERunningLock

+ (MMERunningLock *)lockedRunningLock {
    MMERunningLock *running = [MMERunningLock new];
    [running lock];
    return running ;
}

- (BOOL) runUntilTimeout:(NSTimeInterval)lockTimeout withQuantum:(NSTimeInterval)quantum{
    BOOL didLock = NO;
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:lockTimeout];
    while (!(didLock = [self lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:(quantum / 2)]])) { // block for 1/2 Q
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(quantum / 2)]]; // run for 1/2 Q
        if (timeout.timeIntervalSinceNow < 0) {
            break;
        }
    }
    return didLock;
}

- (BOOL) runUntilTimeout:(NSTimeInterval)lockTimeout {
    return [self runUntilTimeout:lockTimeout withQuantum:0.1];
}

@end
