#import <XCTest/XCTest.h>
#import "MMENSDateWrapper.h"

@interface MMENSDateWrapperTests : XCTestCase

@end

@implementation MMENSDateWrapperTests

- (void)testExample {
    MMENSDateWrapper *dateWrapper = [[MMENSDateWrapper alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:213242];
    NSString *dateString = [dateWrapper formattedDateStringForDate:date];    
    XCTAssertEqualObjects(dateString, @"1970-01-03T11:14:02:000+0000");
}

@end
