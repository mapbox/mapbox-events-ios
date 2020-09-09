#import <XCTest/XCTest.h>
//#import <MapboxMobileEvents/MMEEvent.h>
@import MapboxMobileEvents;

@interface MMEEventTests : XCTestCase

@end

@implementation MMEEventTests

- (void)setUp {
    
}

- (void)testEventsWithoutName {
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    MMEEvent *event1 = [MMEEvent eventWithAttributes:attributes];
    MMEEvent *event2 = [MMEEvent eventWithAttributes:attributes];

    NSArray *eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];

    XCTAssert(eventQueue.count == 0);
}


@end
