@import Security;
@import CommonCrypto;

#import "MMECertPin.h"
#import "MMEConstants.h"
#import "MMELogger.h"

#import "NSUserDefaults+MMEConfiguration.h"

// MARK: ASN1 Headers

// These are the ASN1 headers for the Subject Public Key Info section of a certificate
static const unsigned char rsa2048Asn1Header[] = {
    0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
};

static const unsigned char rsa4096Asn1Header[] = {
    0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00
};

static const unsigned char ecDsaSecp256r1Asn1Header[] = {
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00
};

static const unsigned char ecDsaSecp384r1Asn1Header[] = {
    0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00
};

typedef enum {
    MMEKeySizeRSA2048 = 2048,
    MMEKeySizeRSA4096 = 4096,
    MMEKeySizeECC256 = 256,
    MMEKeySizeECC384 = 384
} MMEKeySizes;

BOOL ASN1HeaderForPublicKeyAlgorithm(size_t algo, const unsigned char ** headerBytes, size_t * headerSize) {
    BOOL headerFound = NO;
    switch (algo) {
        case MMEKeySizeRSA2048:
            *headerBytes = (const unsigned char *)&rsa2048Asn1Header;
            *headerSize = sizeof(rsa4096Asn1Header);
            headerFound = YES;
        case MMEKeySizeRSA4096:
            *headerBytes = (const unsigned char *)&rsa4096Asn1Header;
            *headerSize = sizeof(rsa4096Asn1Header);
            headerFound = YES;
        case MMEKeySizeECC256:
            *headerBytes = (const unsigned char *)&ecDsaSecp256r1Asn1Header;
            *headerSize = sizeof(ecDsaSecp256r1Asn1Header);
            headerFound = YES;
        case MMEKeySizeECC384:
            *headerBytes = (const unsigned char *)&ecDsaSecp384r1Asn1Header;
            *headerSize = sizeof(ecDsaSecp384r1Asn1Header);
            headerFound = YES;
    }
    return headerFound;
}

// MARK: -

@interface MMECertPin()

@property (nonatomic) NSMutableDictionary<NSData *, NSData *> *publicKeyInfoHashesCache;
@property (nonatomic) NSURLSessionAuthChallengeDisposition lastAuthChallengeDisposition;

@property (nonatomic) dispatch_queue_t lockQueue;

@end

@implementation MMECertPin

- (instancetype)init {
    if (self = [super init]) {
        _publicKeyInfoHashesCache = [NSMutableDictionary dictionary];
        _lockQueue = dispatch_queue_create("MMECertHashLock", DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

- (void) handleChallenge:(NSURLAuthenticationChallenge * _Nonnull)challenge completionHandler:(void (^ _Nonnull)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        //Domain should be included
        if (![NSUserDefaults.mme_configuration.mme_certificatePinningConfig.allKeys containsObject:challenge.protectionSpace.host]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lastAuthChallengeDisposition = NSURLSessionAuthChallengePerformDefaultHandling;
                completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            });
            MMELog(MMELogInfo, MMEDebugEventTypeCertPinning, ([NSString stringWithFormat:@"%@ excludes domain: %@", self.class, challenge.protectionSpace.host]));
            
            return;
        }
        
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        SecTrustResultType trustResult;
        
        // Validate the certificate chain with the device's trust store anyway
        // This *might* give use revocation checking
        SecTrustEvaluate(serverTrust, &trustResult);
        if (trustResult == kSecTrustResultUnspecified) {
            // Look for a pinned certificate in the server's certificate chain
            long numKeys = SecTrustGetCertificateCount(serverTrust);
            
            BOOL found = NO;
            for (int lc = 0; lc < numKeys; lc++) {
                SecCertificateRef remoteCertificate = SecTrustGetCertificateAtIndex(serverTrust, lc);
                NSData *remoteCertificatePublicKeyHash = [self hashSubjectPublicKeyInfoFromCertificate:remoteCertificate error:nil];
                NSString *publicKeyHashString = [remoteCertificatePublicKeyHash base64EncodedStringWithOptions:0];
                NSArray *pinnedHashStrings = NSUserDefaults.mme_configuration.mme_certificatePinningConfig[challenge.protectionSpace.host];
                
                if ([pinnedHashStrings containsObject:publicKeyHashString]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.lastAuthChallengeDisposition = NSURLSessionAuthChallengeUseCredential;
                        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                    });
                    MMELog(MMELogInfo, MMEDebugEventTypeCertPinning, @"Certificate found and accepted trust!");
                    
                    found = YES;
                    break;
                }
            }

            if (!found) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.lastAuthChallengeDisposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                });
                MMELog(MMELogInfo, MMEDebugEventTypeCertPinning, @"No certificate found; connection canceled");
            }
        }
        else if (trustResult == kSecTrustResultProceed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lastAuthChallengeDisposition = NSURLSessionAuthChallengePerformDefaultHandling;
                completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            });
            MMELog(MMELogInfo, MMEDebugEventTypeCertPinning, @"User granted - Always Trust; proceeding");
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lastAuthChallengeDisposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            });
            MMELog(MMELogInfo, MMEDebugEventTypeCertPinning, @"Certificate chain validation failed; connection canceled");
        }
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastAuthChallengeDisposition = NSURLSessionAuthChallengePerformDefaultHandling;
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        });
        MMELog(MMELogInfo, MMEDebugEventTypeCertPinning, @"Ignoring credentials; default handling for challenge");
    }
    
}

- (NSData *)hashSubjectPublicKeyInfoFromCertificate:(SecCertificateRef)certificate error:(NSError **)inError {
    __block NSData *cachedSubjectPublicKeyInfo;
   
    // Have we seen this certificate before?
    NSData *certificateData = (__bridge_transfer NSData *)(SecCertificateCopyData(certificate));
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_sync(_lockQueue, ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        cachedSubjectPublicKeyInfo = strongSelf.publicKeyInfoHashesCache[certificateData];
    });
    
    if (cachedSubjectPublicKeyInfo) {
        return cachedSubjectPublicKeyInfo;
    }
    
    // We didn't have this certificate in the cache
    // First extract the public key bytes
    size_t publicKeySize = 0;
    NSData *publicKeyData = [self getPublicKeyDataFromCertificate:certificate keySize:&publicKeySize];
    if (publicKeySize == 0 || publicKeyData == nil) {
        *inError = [NSError.alloc initWithDomain:MMEErrorDomain code:MMEInvalidCertificate userInfo:@{
            NSLocalizedDescriptionKey: @"Invalid Certificate"
        }];
        return nil;
    }
    
    // Generate a hash of the subject public key info
    NSMutableData *subjectPublicKeyInfoHash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX shaCtx;
    CC_SHA256_Init(&shaCtx);
    
    const unsigned char * headerBytes = NULL;
    size_t headerSize = 0;
    
    if (!ASN1HeaderForPublicKeyAlgorithm(publicKeySize, &headerBytes, &headerSize)) {
        *inError = [NSError.alloc initWithDomain:MMEErrorDomain code:MMEInvalidPublicKeyAlgo userInfo:@{
            NSLocalizedDescriptionKey: @"Invalid Public Key Algorithim"
        }];
        return nil;
    }
    // Add the missing ASN1 header for public keys to re-create the subject public key info
    CC_SHA256_Update(&shaCtx, headerBytes, sizeof(rsa2048Asn1Header));
    
    // Add the public key
    CC_SHA256_Update(&shaCtx, [publicKeyData bytes], (unsigned int)[publicKeyData length]);
    CC_SHA256_Final((unsigned char *)[subjectPublicKeyInfoHash bytes], &shaCtx);
    
    
    // Store the hash in our memory cache
    dispatch_barrier_sync(_lockQueue, ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        strongSelf.publicKeyInfoHashesCache[certificateData] = subjectPublicKeyInfoHash;
    });
    
    return subjectPublicKeyInfoHash;
}

// MARK: - Generate Public Key Hash

static const NSString *kMMEKeychainPublicKeyTag = @"MMEKeychainPublicKeyTag"; // Used to add and find the public key in the Keychain

// TODO refactor this into a single function with an @avaiable check
- (NSData *)getPublicKeyDataFromCertificate:(SecCertificateRef)certificate keySize:(size_t *)publicKeySize {
    // ****** iOS ******
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 100000
    // Base SDK is iOS 8 or 9
    return [self getPublicKeyDataFromCertificate_legacy_ios:certificate ];
#else
    // Base SDK is iOS 10+ - try to use the unified Security APIs if available
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]
        && [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}])
    {
        // iOS 10+
        return [self getPublicKeyDataFromCertificate_unified:certificate keySize:publicKeySize];
    }
    else
    {
        // iOS 8 or 9
        return [self getPublicKeyDataFromCertificate_legacy_ios:certificate keySize:publicKeySize];
    }
#endif
}

- (NSData *)getPublicKeyDataFromCertificate_legacy_ios:(SecCertificateRef)certificate keySize:(size_t *)publicKeySize
{
    __block NSData *publicKeyData = nil;
    __block OSStatus resultAdd, __block resultDel = noErr;
    SecKeyRef publicKey;
    SecTrustRef tempTrust;
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    
    // Get a public key reference from the certificate
    SecTrustCreateWithCertificates(certificate, policy, &tempTrust);
    SecTrustResultType result;
    SecTrustEvaluate(tempTrust, &result);
    publicKey = SecTrustCopyPublicKey(tempTrust);
    CFRelease(policy);
    CFRelease(tempTrust);
    
    
    /// Extract the actual bytes from the key reference using the Keychain
    // Prepare the dictionary to add the key
    NSMutableDictionary *peerPublicKeyAdd = [[NSMutableDictionary alloc] init];
    peerPublicKeyAdd[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    peerPublicKeyAdd[(__bridge id)kSecAttrApplicationTag] = kMMEKeychainPublicKeyTag;
    peerPublicKeyAdd[(__bridge id)kSecValueRef] = (__bridge id)publicKey;
    
    // Avoid issues with background fetching while the device is locked
    peerPublicKeyAdd[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    
    // Request the key's data to be returned
    peerPublicKeyAdd[(__bridge id)kSecReturnData] = @YES;
    
    // Prepare the dictionary to retrieve and delete the key
    NSMutableDictionary * publicKeyGet = [[NSMutableDictionary alloc] init];
    publicKeyGet[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    publicKeyGet[(__bridge id)kSecAttrApplicationTag] = kMMEKeychainPublicKeyTag;
    publicKeyGet[(__bridge id)kSecReturnData] = @YES;
    
    // Get the key bytes from the Keychain atomically
    dispatch_sync(dispatch_queue_create("MMEKeychainLock", DISPATCH_QUEUE_SERIAL), ^{
        resultAdd = SecItemAdd((__bridge CFDictionaryRef) peerPublicKeyAdd, (void *)&publicKeyData);
        resultDel = SecItemDelete((__bridge CFDictionaryRef)publicKeyGet);
    });
    
    if (publicKeySize) {
        // TODO fetch record the key size for the caller using older API (example below requires 10.10)
        *publicKeySize = MMEKeySizeRSA2048;
    }

    CFRelease(publicKey);
    if ((resultAdd != errSecSuccess) || (resultDel != errSecSuccess)) {
        // Something went wrong with the Keychain we won't know if we did get the right key data
        publicKeyData = nil;
        *publicKeySize = 0;
    }
    
    return publicKeyData;
}

- (NSData *)getPublicKeyDataFromCertificate_unified:(SecCertificateRef)certificate keySize:(size_t *)publicKeySize
{
    // Create an X509 trust using the using the certificate
    SecTrustRef trust;
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustCreateWithCertificates(certificate, policy, &trust);
    
    // Get a public key reference for the certificate from the trust
    SecTrustResultType result;
    SecTrustEvaluate(trust, &result);
    SecKeyRef publicKey = SecTrustCopyPublicKey(trust);
    CFRelease(policy);
    CFRelease(trust);
    
    // Obtain the public key bytes from the key reference
    // Silencing the warning since there is no way to reach here unless we are on iOS 10.0+
    // (this would otherwise warn if compiled for an app supporting < 10.0)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    CFDataRef publicKeyData = SecKeyCopyExternalRepresentation(publicKey, NULL);

    // record the key size for the caller
    if (publicKeySize) {
        CFDictionaryRef keyAttributes = SecKeyCopyAttributes(publicKey);
        CFNumberRef keySizeInBits = CFDictionaryGetValue(keyAttributes, kSecAttrKeySizeInBits);
        if (keySizeInBits) {
            CFNumberGetValue(keySizeInBits, kCFNumberLongType, (void *)publicKeySize);
        }
        if (keyAttributes) {
            CFRelease(keyAttributes);
        }
    }
#pragma clang diagnostic pop

    CFRelease(publicKey);
    
    return (__bridge_transfer NSData *)publicKeyData;
}

@end
