#import <Cedar/Cedar.h>
#import "MMEDate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMENSDateWrapperSpec)

describe(@"MMEDate", ^{

    beforeEach(^{
    });
    
    context(@"- formattedDateStringForDate:", ^{
        
        it(@"has the correct date format", ^{
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:213242];
            NSString *dateString = [MMEDate.iso8601DateFormatter stringFromDate:date];
            
            dateString should equal(@"1970-01-03T11:14:02.000+0000");
        });
        
    });
    
});

SPEC_END
