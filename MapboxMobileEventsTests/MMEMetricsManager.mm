#import <Cedar/Cedar.h>
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMEMetricsManager.h"
#import "MMEConstants.h"
#import "MMEReachability.h"
#import <CoreLocation/CoreLocation.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEMetricsManagerSpec)

describe(@"MMEMetricsManager", ^{
    
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

            it(@"should set MMEEventDateUTC attributes with the correct format", ^{
                NSDictionary* attributes = [manager attributes];

                [dateFormatter dateFromString:attributes[MMEEventDateUTC]] should_not be_nil;
            });
        });
        
        context(@"when incrementing failed HTTP response metrics", ^{
            beforeEach(^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:404 HTTPVersion:nil headerFields:nil];
                NSDictionary *userInfoFake = [NSDictionary dictionaryWithObject:response forKey:MMEResponseKey];
                NSError *errorFake = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFake];
                
                [manager updateMetricsFromEvents:eventQueue request:requestFake error:errorFake];
                [manager updateMetricsFromEvents:eventQueue request:requestFake error:errorFake];
                
                NSHTTPURLResponse *responseTwo = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:500 HTTPVersion:nil headerFields:nil];
                NSDictionary *userInfoFakeTwo = [NSDictionary dictionaryWithObject:responseTwo forKey:MMEResponseKey];
                NSError *errorFakeTwo = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFakeTwo];
                
                [manager updateMetricsFromEvents:eventQueue request:requestFake error:errorFakeTwo];
            });
            
            it(@"should have failedRequests 404 count increased", ^{
                [manager.metrics.failedRequestsDict objectForKey:@"events.mapbox.com, 404"] should equal(@2);
            });
            
            it(@"should have failedRequests 500 count increased", ^{
                [manager.metrics.failedRequestsDict objectForKey:@"events.mapbox.com, 500"] should equal(@1);
            });
            
            it(@"should have all keys count increased", ^{
                [manager.metrics.failedRequestsDict allKeys].count should equal(2);
            });
            
            it(@"should have eventCountFailed count increased", ^{
                manager.metrics.eventCountFailed should equal(6);
            });
            
            it(@"should have request count NOT increased", ^{
                manager.metrics.requests should equal(0);
            });
        });
        
        context(@"when incrementing successful HTTP requests", ^{
            beforeEach(^{
                [manager updateMetricsFromEvents:eventQueue request:requestFake error:nil];
            });
            
            it(@"should have request count increased", ^{
                manager.metrics.requests should equal(1);
            });
        });
        
        context(@"when incrementing data transfer metrics", ^{
            __block NSData *uncompressedData;
            
            beforeEach(^{
                MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
                commonEventData.vendorId = @"vendor-id";
                commonEventData.model = @"model";
                commonEventData.iOSVersion = @"1";
                commonEventData.scale = 42;
                
                MMEEvent *event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
                MMEEvent *eventTwo = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
                
                NSArray *events = @[event, eventTwo];
                
                NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
                [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (event.attributes) {
                        [eventAttributes addObject:event.attributes];
                    }
                }];
                
                uncompressedData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];
                
                [manager updateMetricsFromData:uncompressedData];
            });
            
            it(@"should have totalDataTransfer increase count again", ^{
                manager.metrics.totalDataTransfer should be_greater_than(0);
            });
            
            if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
                it(@"should have wifi data transfer increase count again", ^{
                    manager.metrics.wifiDataTransfer should be_greater_than(0);
                });
            } else {
                it(@"should have cell data transfer increase count again", ^{
                    manager.metrics.cellDataTransfer should be_greater_than(0);
                });
            }
            
            context(@"when incrementing more data transfer metrics", ^{
                beforeEach(^{
                    [manager updateMetricsFromData:uncompressedData];
                });
                
                it(@"should have totalDataTransfer increase count again", ^{
                    manager.metrics.totalDataTransfer should be_greater_than(300);
                });
                
                if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
                    it(@"should have wifi data transfer increase count again", ^{
                        manager.metrics.wifiDataTransfer should be_greater_than(300);
                    });
                } else {
                    it(@"should have cell data transfer increase count again", ^{
                        manager.metrics.cellDataTransfer should be_greater_than(300);
                    });
                }
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
        
    });
});

SPEC_END

