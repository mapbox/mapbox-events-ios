#import <XCTest/XCTest.h>
#import "MMERunningLock.h"

@interface  MMERunningLockTests : XCTestCase
@end

// MARK: -

@implementation  MMERunningLockTests

- (void) testRunninLockUnlockedBeforeTimeout {
    MMERunningLock *runningLock = [MMERunningLock lockedRunningLock];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [runningLock unlock];
        [timer invalidate];
    }];
    XCTAssertNotNil(timer);
    XCTAssertTrue([runningLock runUntilTimeout:1]);
    XCTAssertFalse(timer.isValid);
}

- (void) testRunninLockUnlockedAfterTimeout {
    MMERunningLock *runningLock = [MMERunningLock lockedRunningLock];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [runningLock unlock];
    }];
    XCTAssertNotNil(timer);
    XCTAssertFalse([runningLock runUntilTimeout:0.1]);
    XCTAssertTrue(timer.isValid);
    [timer invalidate]; // don't let this hang around
}

@end
