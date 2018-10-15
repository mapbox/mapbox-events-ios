#import <Cedar/Cedar.h>
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMEMetricsManager.h"
#import "MMEConstants.h"

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
        
    
        context(@"when counting eventQueue metrics", ^{
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
    });
});

SPEC_END

