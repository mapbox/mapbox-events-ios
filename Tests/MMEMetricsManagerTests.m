#import <XCTest/XCTest.h>

#import "MMEMetricsManager.h"
#import "MMEEvent.h"
#import "MMEConstants.h"
#import "MMELogger.h"
#import "MMEMockEventConfig.h"
#import "NSURL+Files.h"
#import "MMEMetrics.h"
#import "MMEDate.h"
#import "MMEReachability.h"
#import "MMEEventFake.h"
#import "CLLocation+Mocks.h"

@interface MMEMetricsManager (Tests)

@property (nonatomic, strong) MMEMetrics *metrics;

- (BOOL)createFrameworkMetricsEventDirectory;
- (NSString *)pendingMetricsEventPath;

@end

@interface MMEMetricsManagerTests : XCTestCase

@property (nonatomic) MMEMetricsManager *metricsManager;
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSArray *eventQueue;

@end

@implementation MMEMetricsManagerTests

- (void)setUp {
    self.metricsManager = [[MMEMetricsManager alloc] initWithConfig:[[MMEMockEventConfig alloc] init]
                                              pendingMetricsFileURL:[NSURL testPendingEventsFile]];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
}

- (void)testCreateFrameworkMetricsEventDirCreatesNewFile {
    NSURL *url = [self.metricsManager.pendingMetricsFileURL URLByDeletingLastPathComponent];
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];

    BOOL frameworkDirCreated = [self.metricsManager createFrameworkMetricsEventDirectory];
    
    XCTAssert(frameworkDirCreated);
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:url.path]);
}

- (void)testUpdateMetricsFromEventQueue {
    NSString *dateString = @"A nice date";
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    MMEEvent *event1 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    MMEEvent *event2 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    
    self.eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];
    
    [self.metricsManager updateMetricsFromEventQueue:self.eventQueue];

    XCTAssertEqual(self.metricsManager.metrics.eventCountTotal, 2);
    XCTAssertEqual(self.metricsManager.metrics.eventCountPerType.count, 1);
    XCTAssert([(NSNumber*)[self.metricsManager.metrics.eventCountPerType objectForKey:MMEEventTypeMapTap] isEqualToNumber: @2]);
    XCTAssertNotNil(self.metricsManager.metrics.recordingStarted);
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

- (void)testDoesNotGenerateTelemetryEarly {

    // Expects Generated Telemetry to be nil if before <x> date
    self.metricsManager.metrics.recordingStarted = [MMEDate dateWithDate:NSDate.distantFuture];
    XCTAssertNil([self.metricsManager generateTelemetryMetricsEvent]);
}

- (void)testDoesGenerateTelemetyAfterDate {
    // Expects Generated Telemetry to be Non-Nil if after <x> date
    self.metricsManager.metrics.recordingStarted = [MMEDate dateWithDate:NSDate.distantPast];
    XCTAssertNotNil([self.metricsManager generateTelemetryMetricsEvent]);
}

- (void)testCoordinateRounding {

    // Coordinates should use less accurate measurements
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.644375, -77.289127);
    [self.metricsManager updateCoordinate:coordinate];

    XCTAssertEqualWithAccuracy(self.metricsManager.metrics.deviceLat, 38.6443, 0.001);
    XCTAssertEqualWithAccuracy(self.metricsManager.metrics.deviceLon, -77.2891, 0.001);
    XCTAssertLessThan(self.metricsManager.metrics.deviceLat, coordinate.latitude);
    XCTAssertGreaterThan(self.metricsManager.metrics.deviceLon, coordinate.longitude);
}

- (void)testUpdateMetricsWithError {

    // When incrementing failed HTTP response metrics
    NSURLRequest* requestFake = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://areallyniceURL"]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"]
                                                              statusCode:404
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    NSDictionary *userInfoFake = [NSDictionary dictionaryWithObject:response
                                                             forKey:MMEResponseKey];
    NSError *errorFake = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFake];

    NSArray* eventQueue = @[errorFake, errorFake];

    [self.metricsManager updateMetricsFromEventCount:eventQueue.count request:requestFake error:errorFake];
    [self.metricsManager updateMetricsFromEventCount:eventQueue.count request:requestFake error:errorFake];

    NSHTTPURLResponse *responseTwo = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:500 HTTPVersion:nil headerFields:nil];
    NSDictionary *userInfoFakeTwo = [NSDictionary dictionaryWithObject:responseTwo forKey:MMEResponseKey];
    NSError *errorFakeTwo = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFakeTwo];

    [self.metricsManager updateMetricsFromEventCount:eventQueue.count request:requestFake error:errorFakeTwo];

    // Should have failedRequests 404 count increased
    NSDictionary *failedRequestsDict = [self.metricsManager.metrics.failedRequestsDict objectForKey:MMEEventKeyFailedRequests];
    XCTAssertEqualObjects([failedRequestsDict objectForKey:@"404"] , @2);

    // Should have failed Requests 500 count increased
    XCTAssertEqualObjects([failedRequestsDict objectForKey:@"500"] , @1);

    // Should have header in dictionary
    XCTAssertNotNil([self.metricsManager.metrics.failedRequestsDict objectForKey:MMEEventKeyHeader]);

    // Should have all keys count increased
    XCTAssertEqual([self.metricsManager.metrics.failedRequestsDict allKeys].count, 2);

    // Should have eventCountFailed count increased (But this isn't increasing?)
    XCTAssertEqual(self.metricsManager.metrics.eventCountFailed, 6);

    // Should not have total count increase
    XCTAssertEqual(self.metricsManager.metrics.eventCountTotal, 0);

    // Should have request count NOT increased
    XCTAssertEqual(self.metricsManager.metrics.requests, 0);
}

-(void)testUpdateMetricsWithSuccess {
    NSURLRequest* requestFake = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://areallyniceURL"]];

    // When incrementing successful HTTP requests
    [self.metricsManager updateMetricsFromEventCount:1 request:requestFake error:nil];
    XCTAssertEqual(self.metricsManager.metrics.requests, 1);
}

-(void)testUpdateDataAnalyticsOnWifi {

    MMEEvent *event = [MMEEvent locationEventWithID:@"instance-id-1" location:CLLocation.mapboxOffice];
    MMEEvent *eventTwo = [MMEEvent locationEventWithID:@"instance-id-2" location:CLLocation.mapboxOffice];

    NSArray *attributes = @[
        event.attributes,
        eventTwo.attributes
    ];

    NSData* uncompressedData = [NSJSONSerialization dataWithJSONObject:attributes options:0 error:nil];

    // Configure Metrics Manager to treat data transfer as on Wifi Network
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithConfig:[[MMEMockEventConfig alloc] init]
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]
                                                                   onMetricsError:^(NSError * _Nonnull error) {}
                                                               onMetricsException:^(NSException * _Nonnull exception) {}
                                                               isReachableViaWifi:^BOOL{
        return YES;
    }];

    [metricsManager updateSentBytes:uncompressedData.length];
    [metricsManager updateReceivedBytes:uncompressedData.length];

    XCTAssertEqual(metricsManager.metrics.wifiBytesSent, uncompressedData.length);
    XCTAssertEqual(metricsManager.metrics.wifiBytesReceived, uncompressedData.length);
    XCTAssertEqual(metricsManager.metrics.cellBytesSent, 0);
    XCTAssertEqual(metricsManager.metrics.cellBytesReceived, 0);


    // General Network Traffic
    XCTAssertEqual(metricsManager.metrics.totalBytesSent, uncompressedData.length);
    XCTAssertEqual(metricsManager.metrics.totalBytesReceived, uncompressedData.length);
}

-(void)testUpdateDataAnalyticsOnCarrierNetwork {

    MMEEvent *event = [MMEEvent locationEventWithID:@"instance-id-1" location:CLLocation.mapboxOffice];
    MMEEvent *eventTwo = [MMEEvent locationEventWithID:@"instance-id-2" location:CLLocation.mapboxOffice];

    NSArray *attributes = @[
        event.attributes,
        eventTwo.attributes
    ];

    NSData* uncompressedData = [NSJSONSerialization dataWithJSONObject:attributes options:0 error:nil];

    // Configure Metrics Manager to treat data transfer as on Carrier Network
    MMEMetricsManager* metricsManager = [[MMEMetricsManager alloc] initWithConfig:[[MMEMockEventConfig alloc] init]
                                                            pendingMetricsFileURL:[NSURL testPendingEventsFile]
                                                                   onMetricsError:^(NSError * _Nonnull error) {}
                                                               onMetricsException:^(NSException * _Nonnull exception) {}
                                                               isReachableViaWifi:^BOOL{
        return NO;
    }];

    [metricsManager updateSentBytes:uncompressedData.length];
    [metricsManager updateReceivedBytes:uncompressedData.length];

    XCTAssertEqual(metricsManager.metrics.wifiBytesSent, 0);
    XCTAssertEqual(metricsManager.metrics.wifiBytesReceived, 0);
    XCTAssertEqual(metricsManager.metrics.cellBytesSent, uncompressedData.length);
    XCTAssertEqual(metricsManager.metrics.cellBytesReceived, uncompressedData.length);


    // General Network Traffic
    XCTAssertEqual(metricsManager.metrics.totalBytesSent, uncompressedData.length);
    XCTAssertEqual(metricsManager.metrics.totalBytesReceived, uncompressedData.length);
}

-(void)testNotNilDateAttribute {

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";

    // When preparing attributes
    NSString* dateString = self.metricsManager.attributes[MMEEventDateUTC];

    // Should set MMEEventDateUTC attributes
    XCTAssertNotNil(dateString);

    // Should set MMEEventDateUTC to ISO 8501 Format
    XCTAssertNotNil([dateFormatter dateFromString:dateString]);
}

-(void)testAppWakeupCounter {
    [self.metricsManager incrementAppWakeUpCount];
    [self.metricsManager incrementAppWakeUpCount];

    // When incrementing appWakeUp counter should have appWakeUp count increased
    XCTAssertEqual(self.metricsManager.metrics.appWakeups, 2);
}

-(void)testUpdateConfiguration {
    NSDictionary *fake = [NSDictionary dictionaryWithObject:@"aniceconfig" forKey:@"anicekey"];
    [self.metricsManager updateConfigurationJSON:fake];

    // When capturing configuration, should have a configuration assigned
    XCTAssertNotNil(self.metricsManager.metrics.configResponseDict);
    XCTAssertEqualObjects(fake, self.metricsManager.metrics.configResponseDict);
}

-(void)testLoadPendingTelemetryMetricsEventNil {

    // When storing an event from a future event version
    MMEEventFake *futureVersionEvent = [MMEEventFake eventWithName:@"testName" attributes:@{@"aniceattribute":@"aniceattribute"}];

    NSKeyedArchiver *archiver = [NSKeyedArchiver new];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:futureVersionEvent forKey:NSKeyedArchiveRootObjectKey];

    [archiver.encodedData writeToFile:self.metricsManager.pendingMetricsFileURL.path atomically:YES];

    // Should encode event into memory and return nil when calling loadPendingTelemetryMetricsEvent
    XCTAssertNil([self.metricsManager loadPendingTelemetryMetricsEvent]);
}

@end
