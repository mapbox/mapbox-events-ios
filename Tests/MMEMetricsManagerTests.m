#import <XCTest/XCTest.h>

#import "MMEMetricsManager.h"
#import "MMEEvent.h"
#import "MMEConstants.h"

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
    
    
}

- (void)testCreateFrameworkMetricsEventDirCreatesNewFile {
    NSString *sdkPath = MMEMetricsManager.pendingMetricsEventPath.stringByDeletingLastPathComponent;
    [NSFileManager.defaultManager removeItemAtPath:sdkPath error:nil];
    
    BOOL frameworkDirCreated = [MMEMetricsManager createFrameworkMetricsEventDir];
    
    XCTAssert(frameworkDirCreated);
    XCTAssert([NSFileManager.defaultManager fileExistsAtPath:sdkPath isDirectory:nil]);
}

- (void)testUpdateMetricsFromEventQueue {
    NSString *dateString = @"A nice date";
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    MMEEvent *event1 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    MMEEvent *event2 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    
    self.eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];
    
    [self.metricsManager updateMetricsFromEventQueue:self.eventQueue];
    
    XCTAssert([(NSNumber*)[self.metricsManager.metrics.eventCountPerType objectForKey:@"map.click"] isEqualToNumber: @2]);
}

- (void)testAttributesExcludesNullIsland {
    CLLocation *nullIsland = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    
    [self.metricsManager updateCoordinate:nullIsland.coordinate];
    XCTAssert(self.metricsManager.attributes[MMEEventDeviceLat] == nil);
    XCTAssert(self.metricsManager.attributes[MMEEventDeviceLon] == nil);
}

- (void)testAttributesDoesntExcludesNullFloat {
    CLLocation *notNullIsland = [[CLLocation alloc] initWithLatitude:0.4 longitude:0.2];
    
    [self.metricsManager updateCoordinate:notNullIsland.coordinate];
    XCTAssert([self.metricsManager.attributes[MMEEventDeviceLat] isEqualToNumber:@0.4]);
    XCTAssert([self.metricsManager.attributes[MMEEventDeviceLon] isEqualToNumber:@0.2]);
}

@end
