#import <Cedar/Cedar.h>

#import "MMEDate.h"
#import "MMEEvent.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEEventSpec)

describe(@"MMEEvent", ^{

    context(@"constructors", ^{
        it(@"should init via new", ^{
            MMEEvent *event = [MMEEvent new];

            event should_not be_nil;
        });

        it(@"should init with a date near now", ^{
            MMEEvent *event = [MMEEvent new];
            NSDate *now = [NSDate date];

            round(event.date.timeIntervalSinceReferenceDate) should equal(round(now.timeIntervalSinceReferenceDate));
        });

    });

});

SPEC_END
