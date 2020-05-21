@import XCTest;
@import Foundation;
@import Security;

#import <CommonCrypto/CommonDigest.h>
#import "MMECertPin.h"
#import "MMEMockEventConfig.h"
#import "MMENSURLSessionWrapper.h"

@interface MMENSURLSessionWrapper (MMECertPinTests)

@property (nonatomic) MMECertPin *certPin;

@end

// MARK: -

@interface MMECertPin (Tests)
@property (nonatomic) NSURLSessionAuthChallengeDisposition lastAuthChallengeDisposition;

- (NSData *)getPublicKeyDataFromCertificate_legacy_ios:(SecCertificateRef)certificate;

@end

// MARK: -

@interface MMECertPinTests : XCTestCase

@end

// MARK: -

@implementation MMECertPinTests

- (void)setUp {
    // TODO: Validate MMECertPin Responsibilities
    NSURLSessionConfiguration* sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration;
    MMEMockEventConfig* eventConfig = [[MMEMockEventConfig alloc] init];
    MMECertPin* certPin = [[MMECertPin alloc] initWithConfig:eventConfig];
//    dispatch_queue_t queue = dispatch_queue_create(@"com.mapbox.tests.CertPin", DISPATCH_QUEUE_SERIAL)
    dispatch_queue_t queue = dispatch_queue_create(
                                                   [[NSString stringWithFormat:@"com.mapbox.tests.%@", NSStringFromClass([self class])] UTF8String], DISPATCH_QUEUE_SERIAL
                                                   );
    
    [[MMENSURLSessionWrapper alloc] initWithConfiguration:sessionConfiguration
                                          completionQueue:queue
                                                  certPin:certPin];
}

@end
