#import <Cedar/Cedar.h>
#import "MMEDependencyManager.h"
#import "MMECLLocationManagerWrapper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEDependencyManagerSpec)

describe(@"MMEDependencyManager", ^{
    
    __block MMEDependencyManager *manager;
    
    beforeEach(^{
        manager = [MMEDependencyManager sharedManager];
    });
    
    describe(@"- locationManagerWrapperInstance", ^{
        
        it(@"returns expected instance of locationManager", ^{
            [manager locationManagerWrapperInstance] should be_instance_of([MMECLLocationManagerWrapper class]);
        });
        
    });
    
});

SPEC_END
