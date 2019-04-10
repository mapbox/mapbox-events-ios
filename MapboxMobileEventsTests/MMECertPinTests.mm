#import <Cedar/Cedar.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "MMECertPin.h"
#import "MMEEventsConfiguration.h"
#import "MMEPinningConfigurationProvider.h"
#import "MMENSURLSessionWrapper.h"
#import "MMEAPIClientFake.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMENSURLSessionWrapper (MMECertPinTests)

@property (nonatomic) MMECertPin *certPin;

@end

#pragma mark -

@interface MMECertPin (Tests)

@property (nonatomic) MMEPinningConfigurationProvider *pinningConfigProvider;

- (NSData *)getPublicKeyDataFromCertificate_legacy_ios:(SecCertificateRef)certificate;

@end

#pragma mark -

SPEC_BEGIN(MMECertPinSpec)

describe(@"MMECertPin", ^{
    
    __block MMENSURLSessionWrapper *sessionWrapper;
    __block MMEEventsConfiguration *configuration;
    __block NSArray *blacklistFake;
    
    beforeEach(^{
        configuration = [MMEEventsConfiguration configuration];
        sessionWrapper = [[MMENSURLSessionWrapper alloc] init];
        blacklistFake = [NSArray arrayWithObjects:@"i/4rsupujT8Ww/2yIGJ3wb6R7GDw2FHPyOM5sWh87DQ=", @"+1CHLRDE6ehp61cm8+NDMvd32z0Qc4bgnZRLH0OjE94=", nil];
        configuration.blacklist = blacklistFake;
    });
    
    it(@"should have china hash array with a count of 54", ^{
        NSArray *cnHashes = sessionWrapper.certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.cn"][kMMEPublicKeyHashes];
        cnHashes.count should equal(54);
    });
    
    it(@"should have .com hash array with a count of 54", ^{
        NSArray *comHashes = sessionWrapper.certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.com"][kMMEPublicKeyHashes];
        comHashes.count should equal(54);
    });
    
    describe(@"- updateHashesWithConfiguration", ^{
        beforeEach(^{
            [sessionWrapper reconfigure:configuration];
        });
        
        context(@"when hashes have been updated", ^{
            
            it(@"should remove blacklisted hashes from .cnHashes", ^{
                NSArray *cnHashes = sessionWrapper.certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.cn"][kMMEPublicKeyHashes];
                cnHashes.count should equal(53);
            });
            
            it(@"should remove blacklisted hashes from .comHashes", ^{
                NSArray *comHashes = sessionWrapper.certPin.pinningConfigProvider.pinningConfig[kMMEPinnedDomains][@"events.mapbox.com"][kMMEPublicKeyHashes];
                comHashes.count should equal(53);
            });
        });
    });

    it(@"should support legacy ios devices", ^{
        NSString *testCARoot = @"MMETestCARoot";
        NSBundle *testsBundle = [NSBundle bundleForClass:MMEAPIClientFake.class];
        NSString *testCARootCertPath = [testsBundle pathForResource:testCARoot ofType:@"cer"];
        NSData *testCARootCertData = [NSData dataWithContentsOfFile:testCARootCertPath];
        SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)testCARootCertData);

        certificate should_not be_nil;

        // for get publicKeyData to work we need to put MMETestCARoot into the keychain
        NSDictionary *addQuery = @{
            (id)kSecValueRef: (__bridge id)certificate,
            (id)kSecClass: (id)kSecClassCertificate,
            (id)kSecAttrLabel: testCARoot
        };

        SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);

        NSData* publicKey = [sessionWrapper.certPin getPublicKeyDataFromCertificate_legacy_ios:certificate];
        publicKey should_not be_nil;
    });
});

SPEC_END
