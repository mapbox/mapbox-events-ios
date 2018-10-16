#import <Cedar/Cedar.h>
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMEMetricsManager.h"
#import "MMEConstants.h"
#import "MMEReachability.h"

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
        
        beforeEach(^{
            NSString *dateString = @"A nice date";
            NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
            
            MMEEvent *event1 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
            MMEEvent *event2 = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
            eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];
        });
        
    
        context(@"when incrementing eventQueue metrics", ^{
            beforeEach(^{
                [manager metricsFromEventQueue:eventQueue];
            });
            
            it(@"should have total count increase", ^{
                manager.eventCountTotal should equal(2);
            });
            
            it(@"should have event count per type increase", ^{
                manager.eventCountPerType.count should equal(1);
            });
            
            it(@"should have event count per type object count increase", ^{
                [manager.eventCountPerType objectForKey:MMEEventTypeMapTap] should equal(@2);
            });
        });
        
        context(@"when incrementing failed HTTP response metrics", ^{
            beforeEach(^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:404 HTTPVersion:nil headerFields:nil];
                NSDictionary *userInfoFake = [NSDictionary dictionaryWithObject:response forKey:MMEResponseKey];
                NSError *errorFake = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFake];
                
                [manager metricsFromEvents:eventQueue andError:errorFake];
                [manager metricsFromEvents:eventQueue andError:errorFake];
                
                NSHTTPURLResponse *responseTwo = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"events.mapbox.com"] statusCode:500 HTTPVersion:nil headerFields:nil];
                NSDictionary *userInfoFakeTwo = [NSDictionary dictionaryWithObject:responseTwo forKey:MMEResponseKey];
                NSError *errorFakeTwo = [NSError errorWithDomain:@"test" code:42 userInfo:userInfoFakeTwo];
                
                [manager metricsFromEvents:eventQueue andError:errorFakeTwo];
            });
            
            it(@"should have failedRequests 404 count increased", ^{
                [manager.failedRequestsDict objectForKey:@"events.mapbox.com, 404"] should equal(@2);
            });
            
            it(@"should have failedRequests 500 count increased", ^{
                [manager.failedRequestsDict objectForKey:@"events.mapbox.com, 500"] should equal(@1);
            });
            
            it(@"should have all keys count increased", ^{
                [manager.failedRequestsDict allKeys].count should equal(2);
            });
            
            it(@"should have eventCountFailed count increased", ^{
                manager.eventCountFailed should equal(6);
            });
            
            it(@"should have request count NOT increased", ^{
                manager.requests should equal(0);
            });
        });
        
        context(@"when incrementing successful HTTP requests", ^{
            beforeEach(^{
                [manager metricsFromEvents:eventQueue andError:nil];
            });
            
            it(@"should have request count increased", ^{
                manager.requests should equal(1);
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
                
                [manager metricsFromData:uncompressedData];
            });
            
            it(@"should have totalDataTransfer increase count again", ^{
                manager.totalDataTransfer should be_greater_than(0);
            });
            
            if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
                it(@"should have wifi data transfer increase count again", ^{
                    manager.wifiDataTransfer should be_greater_than(0);
                });
            } else {
                it(@"should have cell data transfer increase count again", ^{
                    manager.cellDataTransfer should be_greater_than(0);
                });
            }
            
            context(@"when incrementing more data transfer metrics", ^{
                beforeEach(^{
                    [manager metricsFromData:uncompressedData];
                });
                
                it(@"should have totalDataTransfer increase count again", ^{
                    manager.totalDataTransfer should be_greater_than(300);
                });
                
                if ([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]) {
                    it(@"should have wifi data transfer increase count again", ^{
                        manager.wifiDataTransfer should be_greater_than(300);
                    });
                } else {
                    it(@"should have cell data transfer increase count again", ^{
                        manager.cellDataTransfer should be_greater_than(300);
                    });
                }
            });
        });
        context(@"when incrementing appWakeUp counter ", ^{
            beforeEach(^{
                [manager incrementAppWakeUpCount];
                [manager incrementAppWakeUpCount];
            });
            
            it(@"should have appWakeUp count increased", ^{
                manager.appWakeups should equal(2);
            });
        });
        
    });
});

SPEC_END

