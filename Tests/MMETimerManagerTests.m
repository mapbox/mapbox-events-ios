#import <XCTest/XCTest.h>

#import "MMETimerManager.h"

@interface MMETimerManagerTests : XCTestCase

@property (nonatomic) XCTestExpectation *timerSelectorCompletionExpectation;

@end

@interface MMETimerManager (Test)

@property (nonatomic) NSTimer *timer;

@end

@implementation MMETimerManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testExample {
    self.timerSelectorCompletionExpectation = [self expectationWithDescription:@"It should message the selector"];
    
    MMETimerManager *timerManager = [[MMETimerManager alloc] initWithTimeInterval:1 target:self selector:@selector(workToDoWhenTimerCompletes)];
    [timerManager start];
    
    [self waitForExpectations:@[self.timerSelectorCompletionExpectation] timeout:2];
    
    [timerManager cancel];
    XCTAssertNil(timerManager.timer);
}

- (void)workToDoWhenTimerCompletes {
    [self.timerSelectorCompletionExpectation fulfill];
}

@end
