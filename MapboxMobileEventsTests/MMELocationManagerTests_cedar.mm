#import <Cedar/Cedar.h>
#import "MMELocationManager.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMELocationManager (Spec)

@property (nonatomic) BOOL hostAppHasBackgroundCapability;

@end

SPEC_BEGIN(MMELocationManagerSpec)

describe(@"MMELocationManager", ^{
    
    __block MMELocationManager *locationManager;
    
    context(@"when the host app has background capability and always permissions", ^{
        beforeEach(^{
            
            // TODO: spy_on [NSBundle mainBundle] and stub_method objectForInfoDictionaryKey for the UIBackgroundModes key
            
            locationManager = [[MMELocationManager alloc] init];
        });
        
        // TODO: implement this assertion block
        it(@"caches background capability", PENDING);
    });
    
});

SPEC_END
