#import <Cedar/Cedar.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MudSpec)

describe(@"My name", ^{
    __block NSString *string;
    
    beforeEach(^{
        string = @"My name";
    });
    
    it(@"should be Mud", ^{
        string should contain(@"Mud");
    });
});

SPEC_END
