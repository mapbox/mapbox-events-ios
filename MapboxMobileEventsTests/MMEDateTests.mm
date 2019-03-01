#import <Cedar/Cedar.h>
#import "MMEDate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEDateSpec)

describe(@"MMEDate", ^{

    NSTimeInterval const interval = 60; // just a minute

    beforeEach(^{
    });

    context(@"+ recordTimeOffsetFromServer:", ^{
        it(@"computes offsets from server time", ^{
            NSDate* serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
            NSTimeInterval recorded = [MMEDate recordTimeOffsetFromServer:serverTime];

            round(recorded) should equal(round(interval));
        });
    });

    context(@"+ recordedTimeOffsetFromServer:", ^{
        it(@"records computed offset from server time", ^{
            NSDate *serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
            NSTimeInterval computed = [MMEDate recordTimeOffsetFromServer:serverTime];
            NSTimeInterval recorded = [MMEDate recordedTimeOffsetFromServer];

            round(computed) should equal(round(interval));
            round(recorded) should equal(round(interval));
        });
    });

    context(@"- initWithOffset:", ^{
        it(@"correctly records offsetFromServer", ^{
            MMEDate *offset = [MMEDate.alloc initWithOffset:interval];

            offset.offsetFromServer should equal(interval);
        });
    });

    context(@"- offsetToServer:", ^{
        it(@"correctly computes offsetToServer date", ^{
            NSDate* serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
            MMEDate *offset = [MMEDate.alloc initWithOffset:interval];

            round(offset.offsetToServer.timeIntervalSinceReferenceDate) should equal(round(serverTime.timeIntervalSinceReferenceDate));
        });
    });

    context(@"+ iso8601DateFormatter stringFromDate:", ^{
        it(@"has the correct date format", ^{
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:213242];
            NSString *dateString = [MMEDate.iso8601DateFormatter stringFromDate:date];
            
            dateString should equal(@"1970-01-03T11:14:02.000+0000");
        });
    });
    
});

SPEC_END
