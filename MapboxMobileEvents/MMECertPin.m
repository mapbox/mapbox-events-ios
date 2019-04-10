#import <CommonCrypto/CommonDigest.h>

#import "MMECertPin.h"
#import "MMEPinningConfigurationProvider.h"
#import "MMEEventsConfiguration.h"
#import "MMEEventLogger.h"
#import "MMEConstants.h"

@interface MMECertPin()

@property (nonatomic) MMEPinningConfigurationProvider *pinningConfigProvider;
@property (nonatomic) NSMutableSet<NSData *> *serverSSLPinsSet;
@property (nonatomic) NSMutableDictionary<NSData *, NSData *> *publicKeyInfoHashesCache;
@property (nonatomic) NSMutableSet<NSString *> *excludeSubdomainsSet;
@property (nonatomic) NSURLSessionAuthChallengeDisposition lastAuthChallengeDisposition;

@property (nonatomic) dispatch_queue_t lockQueue;

@end

@implementation MMECertPin

- (instancetype)init {
    if (self = [super init]) {
        _pinningConfigProvider = [MMEPinningConfigurationProvider pinningConfigProviderWithConfiguration:nil];
        _serverSSLPinsSet = [NSMutableSet set];
        _excludeSubdomainsSet = [NSMutableSet set];
        _publicKeyInfoHashesCache = [NSMutableDictionary dictionary];
        _lockQueue = dispatch_queue_create("MMECertHashLock", DISPATCH_QUEUE_CONCURRENT);

        [self updateSSLPinSet];
    }

    return self;
}

- (void) updateSSLPinSet {
    [self.serverSSLPinsSet removeAllObjects];
    [self.publicKeyInfoHashesCache removeAllObjects];
    
    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                MMEEventKeyLocalDebugDescription: @"Updating SSL pin set..."}];

    if ([self.pinningConfigProvider.pinningConfig.allKeys containsObject:kMMEPinnedDomains]) {
        NSDictionary *configPinnedDomains = self.pinningConfigProvider.pinningConfig[kMMEPinnedDomains];

        for (NSString *pinnedDomain in configPinnedDomains.allKeys) {
            NSDictionary *pinnedDomainConfig = configPinnedDomains[pinnedDomain];

            if ([pinnedDomainConfig.allKeys containsObject:kMMEPublicKeyHashes]) {
                for (NSString *pinnedKeyHashBase64 in pinnedDomainConfig[kMMEPublicKeyHashes]) {
                    NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:pinnedKeyHashBase64 options:(NSDataBase64DecodingOptions)0];
                    if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){
                        // The subject public key info hash doesn't have a valid size
                        [NSException raise:@"Hash value invalid" format:@"Hash value invalid: %@", pinnedKeyHash];
                    }
                    [_serverSSLPinsSet addObject:pinnedKeyHash];
                }
            }

            if ([pinnedDomainConfig.allKeys containsObject:kMMEExcludeSubdomainFromParentPolicy]
             && [pinnedDomainConfig[kMMEExcludeSubdomainFromParentPolicy] boolValue]) {
                [_excludeSubdomainsSet addObject:pinnedDomain];
            }
        }
    }
}

- (void) updateWithConfiguration:(MMEEventsConfiguration *)configuration {
    if (configuration && configuration.blacklist && configuration.blacklist.count > 0) {
        NSString *debugDescription = [NSString stringWithFormat:@"blacklisted hash(s) found: %@", configuration.blacklist];
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                    MMEEventKeyLocalDebugDescription: debugDescription}];
        
        self.pinningConfigProvider = [MMEPinningConfigurationProvider pinningConfigProviderWithConfiguration:configuration];

        [self updateSSLPinSet];
    }
}

- (void) handleChallenge:(NSURLAuthenticationChallenge * _Nonnull)challenge completionHandler:(void (^ _Nonnull)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        //Domain should be excluded
        for (NSString *excludeSubdomains in _excludeSubdomainsSet) {
            if ([challenge.protectionSpace.host isEqualToString:excludeSubdomains]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.lastAuthChallengeDisposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
                });
                
                NSString *debugDescription = [NSString stringWithFormat:@"Excluded subdomain(s): %@", excludeSubdomains];
                [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                            MMEEventKeyLocalDebugDescription: debugDescription}];
                
                return;
            }
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
                NSData *remoteCertificatePublicKeyHash = [self hashSubjectPublicKeyInfoFromCertificate:remoteCertificate];
                
                if ([_serverSSLPinsSet containsObject:remoteCertificatePublicKeyHash]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.lastAuthChallengeDisposition = NSURLSessionAuthChallengeUseCredential;
                        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                    });
                    
                    [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                                MMEEventKeyLocalDebugDescription: @"Certificate found and accepted trust!"}];
                    
                    found = YES;
                    break;
                }
            }

            if (!found) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.lastAuthChallengeDisposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                });
                
                [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                            MMEEventKeyLocalDebugDescription: @"No certificate found; connection canceled"}];
            }
        }
        else if (trustResult == kSecTrustResultProceed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lastAuthChallengeDisposition = NSURLSessionAuthChallengePerformDefaultHandling;
                completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            });
            
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                        MMEEventKeyLocalDebugDescription: @"User granted - Always Trust; proceeding"}];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lastAuthChallengeDisposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            });
            
            [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                        MMEEventKeyLocalDebugDescription: @"Certificate chain validation failed; connection canceled"}];
        }
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastAuthChallengeDisposition = NSURLSessionAuthChallengePerformDefaultHandling;
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        });
        
        [MMEEventLogger.sharedLogger pushDebugEventWithAttributes:@{MMEDebugEventType: MMEDebugEventTypeCertPinning,
                                                                    MMEEventKeyLocalDebugDescription: @"Ignoring credentials; default handling for challenge"}];
    }
    
}

- (NSData *)hashSubjectPublicKeyInfoFromCertificate:(SecCertificateRef)certificate{
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
    NSData *publicKeyData = [self getPublicKeyDataFromCertificate:certificate];
    if (publicKeyData == nil) {
        return nil;
    }
    
    // Generate a hash of the subject public key info
    NSMutableData *subjectPublicKeyInfoHash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX shaCtx;
    CC_SHA256_Init(&shaCtx);
    
    // Add the missing ASN1 header for public keys to re-create the subject public key info
    CC_SHA256_Update(&shaCtx, rsa2048Asn1Header, sizeof(rsa2048Asn1Header));
    
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

#pragma mark - Generate Public Key Hash

static const NSString *kMMEKeychainPublicKeyTag = @"MMEKeychainPublicKeyTag"; // Used to add and find the public key in the Keychain

// These are the ASN1 headers for the Subject Public Key Info section of a certificate
static const unsigned char rsa2048Asn1Header[] = {
    0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
};

- (NSData *)getPublicKeyDataFromCertificate:(SecCertificateRef)certificate{
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
        return [self getPublicKeyDataFromCertificate_unified:certificate];
    }
    else
    {
        // iOS 8 or 9
        return [self getPublicKeyDataFromCertificate_legacy_ios:certificate];
    }
#endif
}

- (NSData *)getPublicKeyDataFromCertificate_legacy_ios:(SecCertificateRef)certificate
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
    
    CFRelease(publicKey);
    if ((resultAdd != errSecSuccess) || (resultDel != errSecSuccess))
    {
        // Something went wrong with the Keychain we won't know if we did get the right key data
        publicKeyData = nil;
    }
    
    return publicKeyData;
}

- (NSData *)getPublicKeyDataFromCertificate_unified:(SecCertificateRef)certificate
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
#pragma clang diagnostic pop
    
    CFRelease(publicKey);
    
    return (__bridge_transfer NSData *)publicKeyData;
}

@end
