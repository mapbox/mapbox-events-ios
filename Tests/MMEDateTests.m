#import <XCTest/XCTest.h>

#import "MMEDate.h"

@interface MMEDateTests : XCTestCase

@end

@implementation MMEDateTests

- (void)setUp {
    
}

- (void)testHTTPDateFormatter {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:214123];
    NSString *dateString = [MMEDate.HTTPDateFormatter stringFromDate:date];
    
    XCTAssert([dateString isEqualToString:@"Sat, 3 Jan 1970 03:28:43 -0800"]);
}

@end
