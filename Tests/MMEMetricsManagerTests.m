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
    CLLocation *notNullIsland = [[CLLocation alloc] initWithLatitude:4 longitude:2];
    
    [self.metricsManager updateCoordinate:notNullIsland.coordinate];
    XCTAssert([self.metricsManager.attributes[MMEEventDeviceLat] isEqualToNumber:@4]);
    XCTAssert([self.metricsManager.attributes[MMEEventDeviceLon] isEqualToNumber:@2]);
}

// TODO: - Convert Cedar Tests

/*
__block MMEMetricsManager *manager;

beforeEach(^{
    manager = [[MMEMetricsManager alloc] init];
});

describe(@"- MMEMetricsManagerInstance", ^{

__block NSArray *eventQueue;
__block NSDateFormatter *dateFormatter;
__block NSURLRequest *requestFake;

beforeEach(^{
    NSString *dateString = @"A nice date";
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    MMEEvent *event1 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    MMEEvent *event2 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
    eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];
    
    requestFake = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://areallyniceURL"]];
});

context(@"when incrementing eventQueue metrics", ^{
    beforeEach(^{
        [manager updateMetricsFromEventQueue:eventQueue];
    });
    
    it(@"should have total count increase", ^{
        manager.metrics.eventCountTotal should equal(2);
    });
    
    it(@"should have event count per type increase", ^{
        manager.metrics.eventCountPerType.count should equal(1);
    });
    
    it(@"should have event count per type object count increase", ^{
        [manager.metrics.eventCountPerType objectForKey:MMEEventTypeMapTap] should equal(@2);
    });
    
    it(@"should set recordingStarted date", ^{
        manager.metrics.recordingStarted should_not be_nil;
    });
});

context(@"when preparing attributes", ^{
    __block NSString *dateString = nil;

    beforeEach(^{
        dateString = manager.attributes[MMEEventDateUTC];
    });

    it(@"should set MMEEventDateUTC attributes", ^{
        dateString should_not be_nil;
    });

    it(@"should set MMEEventDateUTC to ISO 8501 Format", ^{
        [dateFormatter dateFromString:dateString] should_not be_nil;
    });
});

context(@"when incrementing failed HTTP response metrics", ^{
    beforeEach(^{
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:404 HTTPVersion:nil headerFields:nil];
        NSDictionary *userInfoFake = [NSDictionary dictionaryWithObject:response forKey:MMEResponseKey];
        NSError *errorFake = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFake];
        
        [manager updateMetricsFromEventCount:eventQueue.count request:requestFake error:errorFake];
        [manager updateMetricsFromEventCount:eventQueue.count request:requestFake error:errorFake];
        
        NSHTTPURLResponse *responseTwo = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:500 HTTPVersion:nil headerFields:nil];
        NSDictionary *userInfoFakeTwo = [NSDictionary dictionaryWithObject:responseTwo forKey:MMEResponseKey];
        NSError *errorFakeTwo = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFakeTwo];
        
        [manager updateMetricsFromEventCount:eventQueue.count request:requestFake error:errorFakeTwo];
    });
    
    it(@"should have failedRequests 404 count increased", ^{
        NSDictionary *failedRequestsDict = [manager.metrics.failedRequestsDict objectForKey:MMEEventKeyFailedRequests];
        [failedRequestsDict objectForKey:@"404"] should equal(@2);
    });
    
    it(@"should have failedRequests 500 count increased", ^{
        NSDictionary *failedRequestsDict = [manager.metrics.failedRequestsDict objectForKey:MMEEventKeyFailedRequests];
        [failedRequestsDict objectForKey:@"500"] should equal(@1);
    });
    
    it(@"should have header in dictionary", ^{
        [manager.metrics.failedRequestsDict objectForKey:MMEEventKeyHeader] should_not be_nil;
    });
    
    it(@"should have all keys count increased", ^{
        [manager.metrics.failedRequestsDict allKeys].count should equal(2);
    });
    
    it(@"should have eventCountFailed count increased", ^{
        manager.metrics.eventCountFailed should equal(6);
    });
    
    it(@"should not have total count increase", ^{
        manager.metrics.eventCountTotal should equal(0);
    });
    
    it(@"should have request count NOT increased", ^{
        manager.metrics.requests should equal(0);
    });
});

context(@"when incrementing successful HTTP requests", ^{
    beforeEach(^{
        [manager updateMetricsFromEventCount:eventQueue.count request:requestFake error:nil];
    });
    
    it(@"should have request count increased", ^{
        manager.metrics.requests should equal(1);
    });
});

context(@"when incrementing data transfer metrics", ^{
    __block NSData *uncompressedData;
    
    beforeEach(^{
        MMEEvent *event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:nil];
        MMEEvent *eventTwo = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:nil];
        
        NSArray *events = @[event, eventTwo];
        
        NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
        [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
            if (event.attributes) {
                [eventAttributes addObject:event.attributes];
            }
        }];
        
        uncompressedData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];
        
        [manager updateSentBytes:uncompressedData.length];
        [manager updateReceivedBytes:uncompressedData.length];
    });
    
    if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
        it(@"should have wifiBytesSent increase count again", ^{
            manager.metrics.wifiBytesSent should be_greater_than(0);
            manager.metrics.wifiBytesReceived should be_greater_than(0);
        });
    } else {
        it(@"should have cellBytesSent increase count again", ^{
            manager.metrics.cellBytesSent should be_greater_than(0);
            manager.metrics.cellBytesReceived should be_greater_than(0);
        });
    }
    
    it(@"should have totalBytes increase count again", ^{
        manager.metrics.totalBytesSent should be_greater_than(0);
        manager.metrics.totalBytesReceived should be_greater_than(0);
    });
    
    context(@"when incrementing more data transfer metrics", ^{
        beforeEach(^{
            [manager updateSentBytes:uncompressedData.length];
            [manager updateReceivedBytes:uncompressedData.length];
        });
        
        if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
            it(@"should have wifiBytesSent increase count again", ^{
                manager.metrics.wifiBytesSent should be_greater_than(300);
                manager.metrics.wifiBytesReceived should be_greater_than(300);
            });
        } else {
            it(@"should have cellBytesSent increase count again", ^{
                manager.metrics.cellBytesSent should be_greater_than(300);
                manager.metrics.cellBytesReceived should be_greater_than(300);
            });
        }
        
        it(@"should have totalBytesSent increase count again", ^{
            manager.metrics.totalBytesSent should be_greater_than(400);
            manager.metrics.totalBytesReceived should be_greater_than(400);
        });
    });
});
context(@"when incrementing appWakeUp counter", ^{
    beforeEach(^{
        [manager incrementAppWakeUpCount];
        [manager incrementAppWakeUpCount];
    });
    
    it(@"should have appWakeUp count increased", ^{
        manager.metrics.appWakeups should equal(2);
    });
});
context(@"when capturing configuration", ^{
    beforeEach(^{
        NSDictionary *configFake = [NSDictionary dictionaryWithObject:@"aniceconfig" forKey:@"anicekey"];
        
        [manager updateConfigurationJSON:configFake];
    });
    
    it(@"should have a configuration assigned", ^{
        manager.metrics.configResponseDict should_not be_nil;
    });
});
context(@"when capturing coordinates", ^{
    __block CLLocation *location;
    
    beforeEach(^{
        location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(38.644375, -77.289127) altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:0.0 timestamp:[NSDate date]];
        
        [manager updateCoordinate:location.coordinate];
    });
    
    it(@"should have less accurate values on deviceLat", ^{
        manager.metrics.deviceLat should be_less_than(location.coordinate.latitude);
    });
    
    it(@"should have less accurate values on deviceLon", ^{
        manager.metrics.deviceLon should be_greater_than(location.coordinate.longitude);
    });
});
context(@"when sending attributes", ^{
    it(@"should not be nil attributes", ^{
        [manager attributes] should_not be_nil;
    });
});
context(@"when storing an event from a future event version", ^{
    it(@"should encode event into memory and return nil when calling loadPendingTelemetryMetricsEvent", ^{
        MMEEventFake *futureVersionEvent = [MMEEventFake eventWithName:@"testName" attributes:@{@"aniceattribute":@"aniceattribute"}];
        
        NSString *pendingMetricFilePath = MMEMetricsManager.pendingMetricsEventPath;
        
        NSKeyedArchiver *archiver = [NSKeyedArchiver new];
        archiver.requiresSecureCoding = YES;
        [archiver encodeObject:futureVersionEvent forKey:NSKeyedArchiveRootObjectKey];
        
        [archiver.encodedData writeToFile:pendingMetricFilePath atomically:YES];
        
        [manager loadPendingTelemetryMetricsEvent] should be_nil;
    });
});
});
});
*/
@end
