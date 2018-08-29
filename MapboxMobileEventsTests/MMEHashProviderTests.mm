
#import <Cedar/Cedar.h>
#import <Foundation/Foundation.h>
#import "MMEHashProvider.h"
#import "MMEEventsConfiguration.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMEHashProvider (Tests)

@end

SPEC_BEGIN(MMEHashProvederSpec)

describe(@"MMEHashProvider", ^{

    __block MMEHashProvider *hashProvider;
    __block MMEEventsConfiguration *configuration;
    __block NSArray *blacklistFake;

    beforeEach(^{
        configuration = [MMEEventsConfiguration configuration];
        hashProvider = [[MMEHashProvider alloc] init];
        
        blacklistFake = [NSArray arrayWithObjects:@"i/4rsupujT8Ww/2yIGJ3wb6R7GDw2FHPyOM5sWh87DQ=", @"+1CHLRDE6ehp61cm8+NDMvd32z0Qc4bgnZRLH0OjE94=", nil];
        
        configuration.blacklist = blacklistFake;
    });

    it(@"should have china hash array with a count of 54", ^{
        hashProvider.cnHashes.count should equal(54);
    });
    
    it(@"should have .com hash array with a count of 54", ^{
        hashProvider.comHashes.count should equal(54);
    });
    
    describe(@"- updateHashesWithConfiguration", ^{
        beforeEach(^{
            [hashProvider updateHashesWithConfiguration:configuration];
        });
        
        context(@"when hashes have been updated", ^{
            
            it(@"should remove blacklisted hashes from .cnHashes", ^{
                hashProvider.cnHashes.count should equal(53);
            });
            
            it(@"should remove blacklisted hashes from .comHashes", ^{
                hashProvider.comHashes.count should equal(53);
            });
        });
    });
});

SPEC_END
