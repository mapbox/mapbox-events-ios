@import XCTest;

#import "MMEConstants.h"
#import "MMEEvent.h"
#import "MMEEventsManager.h"


@interface MMECrashTests : XCTestCase

@end

// MARK: -

@implementation MMECrashTests

- (void)setUp {
    
}

- (void)testReportError {
    NSError *testError = [NSError errorWithDomain:MMEErrorDomain code:-666 userInfo:nil];
    MMEEvent *testEvent = [MMEEventsManager.sharedManager reportError:testError];

    // it should return an event
    XCTAssertNotNil(testEvent);
}

- (void)testReportException {
    NSException *testException = [NSException exceptionWithName:NSGenericException reason:MMEEventKeyErrorNoReason userInfo:nil];
    MMEEvent *testEvent = [MMEEventsManager.sharedManager reportException:testException];

    // it should return an event
    XCTAssertNotNil(testEvent);
}

- (void)testReportRaisedAndCaughtException {
    NSException *testException = [NSException exceptionWithName:NSGenericException reason:MMEEventKeyErrorNoReason userInfo:nil];
    @try {
        [testException raise];
    }
    @catch (NSException *exception) {
        MMEEvent *testEvent = [MMEEventsManager.sharedManager reportException:testException];
        
        // it should return an event
        XCTAssertNotNil(testEvent);
    }
}

@end
