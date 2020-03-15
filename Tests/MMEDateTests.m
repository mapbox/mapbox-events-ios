#import <XCTest/XCTest.h>

#import "MMEDate.h"

@interface MMEDateTests : XCTestCase

@end

// MARK: -

@implementation MMEDateTests

- (void)setUp {
    
}

- (void)testHTTPDateFormatter {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:214123];
    NSString *dateString = [MMEDate.HTTPDateFormatter stringFromDate:date];
<<<<<<< HEAD
    XCTAssert([dateString isEqualToString:@"Sat, 3 Jan 1970 11:28:43 +0000"], @"%@", dateString);
=======
    
    XCTAssert([dateString isEqualToString:@"Sat, 3 Jan 1970 11:28:43 +0000"]);
>>>>>>> Fix tests, remove Cedar targets, remove Cartfiles
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

NSTimeInterval const interval = 60; // just a minute

- (void)testRecordTimeOffsetFromServer {
    NSDate *serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
    NSTimeInterval recorded = [MMEDate recordTimeOffsetFromServer:serverTime];

    // computes offsets from server time
    XCTAssert(lround(recorded) == lround(interval));
}

- (void)testRecordedTimeOffsetFromServer {
    NSDate *serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
    NSTimeInterval computed = [MMEDate recordTimeOffsetFromServer:serverTime];
    NSTimeInterval recorded = [MMEDate recordedTimeOffsetFromServer];

    // checks computed and recorded
    XCTAssert(lround(computed) == lround(recorded));

    // checks the computed interval
    XCTAssert(lround(computed) == lround(interval));

    // check the recorded interval
    XCTAssert(lround(recorded) == lround(interval));
}

- (void)testClearTimeOffsetFromServer {
    NSTimeInterval interval = [MMEDate recordTimeOffsetFromServer:NSDate.date];
    NSTimeInterval recorded = [MMEDate recordedTimeOffsetFromServer];

    // should be a short interval
    XCTAssert(lround(interval) == 0);

    // should have reset the recorded offset
    XCTAssert(lround(recorded) == 0);
}

- (void)testInitWithOffset {
    MMEDate *offset = [MMEDate.alloc initWithOffset:interval];

    // correctly records offsetFromServer
    XCTAssert(lround(offset.offsetFromServer) == lround(interval));
}

- (void)testOffsetToServer {
    NSDate *serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
    MMEDate *offset = [MMEDate.alloc initWithOffset:interval];

    // correctly computes offsetToServer date
    XCTAssert(lround(offset.offsetToServer.timeIntervalSinceReferenceDate) == lround(serverTime.timeIntervalSinceReferenceDate));
}

- (void)testISO8601DateFormatter {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:213242];
    NSString *dateString = [MMEDate.iso8601DateFormatter stringFromDate:date];
    
    XCTAssert([@"1970-01-03T11:14:02.000+0000" isEqualToString:dateString]);
}

- (void)testmme_startOfTomorrow {
    MMEDate *now = MMEDate.date;
    NSDate *later = now.mme_startOfTomorrow;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    // it should be in the future"
    XCTAssert([later timeIntervalSinceDate:now] > 0.0);

    // it should be less than 24 hours in the future
    NSTimeInterval oneDay = (60 * 60 * 24); // S * M * H
    XCTAssert([later timeIntervalSinceDate:now] < oneDay);

    // it should be exactly midnight
    NSUInteger laterHours = [calendar component:NSCalendarUnitHour fromDate:later];
    NSUInteger laterMinutes = [calendar component:NSCalendarUnitMinute fromDate:later];
    NSUInteger laterSeconds = [calendar component:NSCalendarUnitSecond fromDate:later];

    XCTAssert(laterHours == 0);
    XCTAssert(laterMinutes == 0);
    XCTAssert(laterSeconds == 0);
}

- (void)testNSKeyedArchiver {
    MMEDate *now = [MMEDate new];
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MMEDate-now.data"];
    if ([NSFileManager.defaultManager fileExistsAtPath:tempFile]) {
        [NSFileManager.defaultManager removeItemAtPath:tempFile error:nil];
    }
    [NSKeyedArchiver archiveRootObject:now toFile:tempFile];
    NSData *thenData = [NSData dataWithContentsOfFile:tempFile];
    NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:thenData];
    unarchiver.requiresSecureCoding = YES;
    MMEDate *then = [unarchiver decodeObjectOfClass:MMEDate.class forKey:NSKeyedArchiveRootObjectKey];

    // it should write encoded data to a file/read data and decode from a file
    XCTAssert([NSFileManager.defaultManager fileExistsAtPath:tempFile]);

    // it should read data and decode from a file
    XCTAssertNotNil(then);
    XCTAssert(lround(then.timeIntervalSinceReferenceDate) == lround(now.timeIntervalSinceReferenceDate));
}

@end
