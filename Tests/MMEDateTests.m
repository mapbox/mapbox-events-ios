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

- (void)testNSSecureCoding {
    MMEDate *now = [MMEDate new];
    NSKeyedArchiver *archiver = [NSKeyedArchiver new];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:now forKey:NSKeyedArchiveRootObjectKey];
    NSData *nowData = archiver.encodedData;
    
    NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:nowData];
    unarchiver.requiresSecureCoding = YES;
    MMEDate *then = [unarchiver decodeObjectOfClass:MMEDate.class forKey:NSKeyedArchiveRootObjectKey];
    
    XCTAssert(then);
    XCTAssert(then.timeIntervalSinceReferenceDate == now.timeIntervalSinceReferenceDate);
    XCTAssert([then isEqual:now]);
}

- (void)testDescription {
    MMEDate *now = [[MMEDate alloc] initWithTimeIntervalSince1970:224313];
    NSTimeInterval nowServerTime = [MMEDate recordedTimeOffsetFromServer];
    
    //server offset may have been set in a previous test
    NSString *capturedNowDescription = [NSString stringWithFormat:@"<MMEDate sinceReference=-978082887.000000, offsetFromServer=%f>", nowServerTime];
    
    XCTAssert([now.description isEqualToString:capturedNowDescription]);
}

- (void)testOffsetSetting {
    MMEDate *now = [[MMEDate alloc] initWithOffset:200.00];
    XCTAssert(now.offsetFromServer == 200.0);

    MMEDate *then = [MMEDate dateWithOffset:400.00];
    XCTAssert(then.offsetFromServer == 400.0);
}

@end
