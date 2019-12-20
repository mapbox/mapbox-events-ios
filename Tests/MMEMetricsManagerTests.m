#import <XCTest/XCTest.h>

#import "MMEMetricsManager.h"
#import "MMEEvent.h"

@interface MMEMetricsManager (Tests)

+ (BOOL)createFrameworkMetricsEventDir;
+ (NSString *)pendingMetricsEventPath;

@end

@interface MMEMetricsManagerTests : XCTestCase

@property (nonatomic) MMEMetricsManager *metricsManager;
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSArray *eventQueue;

@end

@implementation MMEMetricsManagerTests

- (void)setUp {
    self.metricsManager = [[MMEMetricsManager alloc] init];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    NSString *dateString = @"A nice date";
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    MMEEvent *event1 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    MMEEvent *event2 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    
    self.eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];
}

- (void)tearDown {
    
}

- (void)testCreateFrameworkMetricsEventDirCreatesNewFile {
    NSString *sdkPath = MMEMetricsManager.pendingMetricsEventPath.stringByDeletingLastPathComponent;
    [NSFileManager.defaultManager removeItemAtPath:sdkPath error:nil];
    
    BOOL frameworkDirCreated = [MMEMetricsManager createFrameworkMetricsEventDir];
    
    XCTAssert(frameworkDirCreated);
    XCTAssert([NSFileManager.defaultManager fileExistsAtPath:sdkPath isDirectory:nil]);
}

- (void)testUpdateMetricsFromEventQueue {
    [self.metricsManager updateMetricsFromEventQueue:self.eventQueue];
    
    XCTAssert([(NSNumber*)[self.metricsManager.metrics.eventCountPerType objectForKey:@"map.click"] isEqualToNumber: @2]);
}

@end
