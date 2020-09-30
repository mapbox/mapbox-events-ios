#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMERunningLock : NSLock

/// @return a locked running lock which you can `runUntilTimeout:`
+ (MMERunningLock *)lockedRunningLock;

/// @return YES if the lock was acquired before the timeout, NO if the timeout was reached
- (BOOL) runUntilTimeout:(NSTimeInterval)lockTimeout;

@end

NS_ASSUME_NONNULL_END
