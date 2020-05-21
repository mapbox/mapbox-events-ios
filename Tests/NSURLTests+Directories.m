#import <XCTest/XCTest.h>
#import "NSURL+Directories.h"

@interface NSURLTests : XCTestCase

@end

@implementation NSURLTests

-(void)testDocumentsDirectory {
    XCTAssertEqualObjects([NSURL documentsDirectory].lastPathComponent, @"Documents");
}

-(void)testCachesDirectory {
    XCTAssertEqualObjects([NSURL cachesDirectory].lastPathComponent, @"Caches");
}

-(void)testPendingEventsFile {
    XCTAssertEqualObjects([NSURL pendingEventsFile].lastPathComponent, @"pending-metrics.event");
}

@end
