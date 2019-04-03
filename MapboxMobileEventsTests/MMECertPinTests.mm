#import <Cedar/Cedar.h>
#import <Foundation/Foundation.h>
#import "MMECertPin.h"
#import "MMEEventsConfiguration.h"
#import "MMEPinningConfigurationProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMECertPin (Tests)

@property (nonatomic) MMEPinningConfigurationProvider *pinningConfigProvider;

@end

SPEC_BEGIN(MMECertPinSpec)

describe(@"MMECertPin", ^{
    
    __block MMECertPin *certPin;
    __block MMEEventsConfiguration *configuration;
    __block NSArray *blacklistFake;
    
    beforeEach(^{
        configuration = [MMEEventsConfiguration configuration];
        certPin = [[MMECertPin alloc] init];
        blacklistFake = [NSArray arrayWithObjects:@"i/4rsupujT8Ww/2yIGJ3wb6R7GDw2FHPyOM5sWh87DQ=", @"+1CHLRDE6ehp61cm8+NDMvd32z0Qc4bgnZRLH0OjE94=", nil];
        configuration.blacklist = blacklistFake;
    });
    
    it(@"should have china hash array with a count of 54", ^{
        NSArray *cnHashes = certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.cn"][kMMEPublicKeyHashes];
        cnHashes.count should equal(54);
    });
    
    it(@"should have .com hash array with a count of 54", ^{
        NSArray *comHashes = certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.com"][kMMEPublicKeyHashes];
        comHashes.count should equal(54);
    });
    
    describe(@"- updateHashesWithConfiguration", ^{
        beforeEach(^{
            [certPin updateWithConfiguration:configuration];
        });
        
        context(@"when hashes have been updated", ^{
            
            it(@"should remove blacklisted hashes from .cnHashes", ^{
                NSArray *cnHashes = certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.cn"][kMMEPublicKeyHashes];
                cnHashes.count should equal(53);
            });
            
            it(@"should remove blacklisted hashes from .comHashes", ^{
                NSArray *comHashes = certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.com"][kMMEPublicKeyHashes];
                comHashes.count should equal(53);
            });
        });
    });
});

SPEC_END
