#import <CommonCrypto/CommonDigest.h>

#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEventLogger.h"
#import "NSBundle+MMEMobileEvents.h"
#import "NSProcessInfo+SystemInfo.h"
#import "NSString+MMEVersions.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: -

@implementation NSUserDefaults (MME)

+ (instancetype)mme_configuration {
    static NSUserDefaults *eventsConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventsConfiguration = [NSUserDefaults.alloc initWithSuiteName:MMEConfigurationDomain];
        [eventsConfiguration mme_registerDefaults];
    });

    return eventsConfiguration;
}

+ (void)mme_resetConfiguration {
    [NSUserDefaults.mme_configuration removePersistentDomainForName:MMEConfigurationDomain];
    [NSUserDefaults.mme_configuration removeVolatileDomainForName:MMEConfigurationVolatileDomain];
    [NSUserDefaults.standardUserDefaults synchronize];
}

// MARK: - Register Defaults

/// check for Info.plist keys which change various default configuration values
- (void)mme_registerDefaults {
    CLLocationDistance backgroundGeofence = MMEBackgroundGeofenceDefault;
    NSTimeInterval startupDelay = MMEStartupDelayDefault;
    BOOL collectionEnabledInSimulator = NO;
    
    NSString *profileName = (NSString*)[NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEEventsProfile];
    if ([profileName isEqualToString:MMECustomProfile]) {
        id customRadiusNumber = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMECustomGeofenceRadius];
        if ([customRadiusNumber isKindOfClass:NSNumber.class]) {
            CLLocationDistance infoGeofence = [customRadiusNumber doubleValue];
            
            if (infoGeofence >= MMECustomGeofenceRadiusMinimum
             && infoGeofence <= MMECustomGeofenceRadiusMaximum) {
                backgroundGeofence = infoGeofence;
            }
            else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid geofence radius: %@", customRadiusNumber);
        }
        else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid geofence: %@", customRadiusNumber);

        id startupDelayNumber = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEStartupDelay];
        if ([startupDelayNumber isKindOfClass:NSNumber.class]) {
            NSTimeInterval infoDelay = [startupDelayNumber doubleValue];
            
            if (infoDelay > 0 && infoDelay <= MMEStartupDelayMaximum) {
                startupDelay = infoDelay;
            }
            else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid startup delay: %@", startupDelayNumber);
        }
        else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid startup delay: %@", startupDelayNumber);
    }

    id accountType = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEAccountType];
    if ([accountType isKindOfClass:NSNumber.class]) {
        [self mme_updateFromAccountType:[accountType integerValue]];
    }
    
    // legacy user agent string
    id userAgentBase = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:@"MMEMapboxUserAgentBase"];
    if ([userAgentBase isKindOfClass:NSString.class]) {
        self.mme_legacyUserAgentBase = userAgentBase;
    }
    
    id hostSDKVersion = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:@"MMEMapboxHostSDKVersion"];
    if ([hostSDKVersion isKindOfClass:NSString.class]) {
        self.mme_legacyHostSDKVersion = hostSDKVersion;
    }
    
    id bundleAPIURL = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEGLMapboxAPIBaseURL];
    if (bundleAPIURL) {
        BOOL isCNRegionURL = [bundleAPIURL isEqual:MMEAPIClientBaseChinaAPIURL];
        [self mme_setObject:@(isCNRegionURL) forVolatileKey:MMEIsCNRegion];
    }

    id infoCollectionEnabledInSimulator = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMECollectionEnabledInSimulator];
    if ([infoCollectionEnabledInSimulator isKindOfClass:NSNumber.class]) {
        collectionEnabledInSimulator = [infoCollectionEnabledInSimulator boolValue];
    }
    
    id debugLoggingEnabled = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEDebugLogging];
    if ([debugLoggingEnabled isKindOfClass:NSNumber.class]) {
        [MMEEventLogger.sharedLogger setEnabled:[debugLoggingEnabled boolValue]];
    }

    [self registerDefaults:@{
        MMEStartupDelay: @(startupDelay), // seconds
        MMEBackgroundGeofence: @(backgroundGeofence), // meters
        MMEHorizontalAccuracy: @(MMEHorizontalAccuracyDefault), // meters
        MMEEventFlushCount: @(MMEEventFlushCountDefault), // events
        MMEEventFlushInterval: @(MMEEventFlushIntervalDefault), // seconds
        MMEIdentifierRotationInterval: @(MMEIdentifierRotationIntervalDefault), // 24 hours
        MMEConfigurationUpdateInterval: @(MMEConfigurationUpdateIntervalDefault), // 24 hours
        MMEBackgroundStartupDelay: @(MMEBackgroundStartupDelayDefault), // seconds
        MMECollectionEnabledInSimulator: @(collectionEnabledInSimulator) // boolean
    }];
}

// MARK: - Volitile Domain

- (NSDictionary *)mme_volatileDomain {
    return [self volatileDomainForName:MMEConfigurationVolatileDomain] ?: NSDictionary.new;
}

- (void)mme_setObject:(NSObject *)value forVolatileKey:(MMEVolatileKey *)key {
    NSMutableDictionary *mutatedDomain = self.mme_volatileDomain.mutableCopy;
    mutatedDomain[key] = value;
    [self removeVolatileDomainForName:MMEConfigurationVolatileDomain];
    [self setVolatileDomain:mutatedDomain forName:MMEConfigurationVolatileDomain];
}

- (NSObject *)mme_objectForVolatileKey:(MMEVolatileKey *)key {
    return self.mme_volatileDomain[key];
}

- (void)mme_deleteObjectForVolatileKey:(MMEVolatileKey *)key {
    NSMutableDictionary *mutatedDomain = self.mme_volatileDomain.mutableCopy;
    [mutatedDomain removeObjectForKey:key];
    [self removeVolatileDomainForName:MMEConfigurationVolatileDomain];
    [self setVolatileDomain:mutatedDomain forName:MMEConfigurationVolatileDomain];
}

// MARK: - Persistent Domain

- (NSDictionary*)mme_persistentDomain {
    return [self persistentDomainForName:MMEConfigurationDomain] ?: NSDictionary.new;
}

- (void)mme_setObject:(id)value forPersistentKey:(MMEPersistentKey *)key {
    NSMutableDictionary *persistentDomain = self.mme_persistentDomain.mutableCopy;
    persistentDomain[key] = value;
    [self setPersistentDomain:persistentDomain forName:MMEConfigurationDomain];
}

- (void)mme_deleteObjectForPersistentKey:(MMEPersistentKey *)key {
    NSMutableDictionary *persistentDomain = self.mme_persistentDomain.mutableCopy;
    [persistentDomain removeObjectForKey:key];
    [self setPersistentDomain:persistentDomain forName:MMEConfigurationDomain];
}

// MARK: - Event Manager Configuration

- (NSTimeInterval)mme_startupDelay {
    return (NSTimeInterval)[self doubleForKey:MMEStartupDelay];
}

- (NSUInteger)mme_eventFlushCount {
    return (NSUInteger)[self integerForKey:MMEEventFlushCount];
}

- (NSTimeInterval)mme_eventFlushInterval {
    return (NSTimeInterval)[self doubleForKey:MMEEventFlushInterval];
}

- (NSTimeInterval)mme_identifierRotationInterval {
    return (NSTimeInterval)[self doubleForKey:MMEIdentifierRotationInterval];
}

- (NSTimeInterval)mme_configUpdateInterval {
    return (NSTimeInterval)[self doubleForKey:MMEConfigurationUpdateInterval];
}

- (NSString *)mme_eventTag {
    return (NSString *)[self stringForKey:MMEConfigEventTag];
}

- (NSString *)mme_accessToken {
    return (NSString *)[self mme_objectForVolatileKey:MMEAccessToken];
}

- (void)mme_setAccessToken:(NSString *)accessToken {
    [self mme_setObject:accessToken forVolatileKey:MMEAccessToken];
}

- (NSString *)mme_legacyUserAgentBase {
    return (NSString *)[self mme_objectForVolatileKey:MMELegacyUserAgentBase];
}

- (void)mme_setLegacyUserAgentBase:(NSString *)legacyUserAgentBase {
    [self mme_setObject:legacyUserAgentBase forVolatileKey:MMELegacyUserAgentBase];
    [self mme_deleteObjectForVolatileKey:MMELegacyUserAgent];
}

- (NSString *)mme_legacyHostSDKVersion {
    return (NSString *)[self mme_objectForVolatileKey:MMELegacyHostSDKVersion];
}

- (void)mme_setLegacyHostSDKVersion:(NSString *)legacyHostSDKVersion {
    if (![legacyHostSDKVersion mme_isSemverString]) {
        NSLog(@"WARNING mme_setLegacyHostSDKVersion: version string (%@) is not a valid semantic version string: http://semver.org", legacyHostSDKVersion);
    }

    [self mme_setObject:legacyHostSDKVersion forVolatileKey:MMELegacyHostSDKVersion];
    [self mme_deleteObjectForVolatileKey:MMELegacyUserAgent];
}

- (NSString *)mme_clientId {
    NSString *clientId = [self stringForKey:MMEClientId];
    if (!clientId) {
        clientId = NSUUID.UUID.UUIDString;
        [self mme_setObject:clientId forPersistentKey:MMEClientId];
    }
    return clientId;
}

- (nullable NSString *)mme_configDigestValue {
    return (NSString *)[self stringForKey:MMEConfigDigestHeaderValue];
}

- (void)mme_setConfigDigestValue:(nullable NSString *)digestHeader {
    [self mme_setObject:digestHeader forPersistentKey:MMEConfigDigestHeaderValue];
}

// MARK: - Service Configuration

- (BOOL)mme_isCNRegion {
    BOOL isCNRegion = NO;
    id isCNRegionNumber = [self mme_objectForVolatileKey:MMEIsCNRegion];
    if ([isCNRegionNumber isKindOfClass:NSNumber.class]) {
        isCNRegion = [(NSNumber *)isCNRegionNumber boolValue];
    }
    
    return isCNRegion;
}

- (void)mme_setIsCNRegion:(BOOL) isCNRegion {
    [self mme_setObject:@(isCNRegion) forVolatileKey:MMEIsCNRegion];
}

- (NSURL *)mme_APIServiceURL {
    NSURL *serviceURL = nil;
    id infoPlistObject = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEGLMapboxAPIBaseURL];

    if ([infoPlistObject isKindOfClass:NSURL.class]) {
        serviceURL = infoPlistObject;
    }
    else if ([infoPlistObject isKindOfClass:NSString.class]) {
        serviceURL = [NSURL URLWithString:infoPlistObject];
    }
    else if ([self mme_isCNRegion]) {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseChinaAPIURL];
    }
    else {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseAPIURL];
    }
    
    return serviceURL;
}

- (NSURL *)mme_eventsServiceURL {
    NSURL *serviceURL = nil;
    id infoPlistObject = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEEventsServiceURL];

    if ([infoPlistObject isKindOfClass:NSURL.class]) {
        serviceURL = infoPlistObject;
    }
    else if ([infoPlistObject isKindOfClass:NSString.class]) {
        serviceURL = [NSURL URLWithString:infoPlistObject];
    }
    else if ([self mme_isCNRegion]) {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseChinaEventsURL];
    }
    else {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseEventsURL];
    }
    
    return serviceURL;
}

- (NSURL *)mme_configServiceURL {
    NSURL *serviceURL = nil;
    id infoPlistObject = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEConfigServiceURL];
    
    if ([infoPlistObject isKindOfClass:NSURL.class]) {
        serviceURL = infoPlistObject;
    }
    else if ([infoPlistObject isKindOfClass:NSString.class]) {
        serviceURL = [NSURL URLWithString:infoPlistObject];
    }
    else if ([self mme_isCNRegion]) {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseChinaConfigURL];
    }
    else {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseConfigURL];
    }
    
    return serviceURL;
}

- (NSString *)mme_userAgentString {
    static NSString *userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; v%@; %@; %@)",
             [[NSBundle.mme_mainBundle objectForInfoDictionaryKey:(id)kCFBundleNameKey] mme_stringByRemovingNonUserAgentTokenCharacters]
                ?: NSBundle.mme_mainBundle.bundlePath.lastPathComponent.stringByDeletingPathExtension.mme_stringByRemovingNonUserAgentTokenCharacters,
             NSBundle.mme_mainBundle.mme_bundleVersionString.mme_stringByRemovingNonUserAgentTokenCharacters,
             NSBundle.mme_mainBundle.bundleIdentifier.mme_stringByRemovingNonUserAgentTokenCharacters,
             [[NSBundle.mme_mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey] mme_stringByRemovingNonUserAgentTokenCharacters],
             [NSProcessInfo mme_operatingSystemVersion],
             [NSProcessInfo mme_processorTypeDescription]
        ];
        
        // check all loaded frameworks for mapbox frameworks, record their bundleIdentifier
        NSMutableSet *loadedMapboxBundleIds = NSMutableSet.new;
        for (NSBundle *loaded in [NSBundle.allFrameworks arrayByAddingObjectsFromArray:NSBundle.allBundles]) {
            if (loaded.bundleIdentifier
             && loaded.bundleIdentifier != NSBundle.mme_mainBundle.bundleIdentifier
             && [loaded.bundleIdentifier rangeOfString:@"mapbox" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [loadedMapboxBundleIds addObject:loaded.bundleIdentifier];
            }
        }
        
        // sort the bundleIdentifiers, then use them to build the User-Agent string
        NSArray *sortedBundleIds = [loadedMapboxBundleIds sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]]];
        for (NSString *bundleId in sortedBundleIds) {
            NSBundle *loaded = [NSBundle bundleWithIdentifier:bundleId];
            NSString *uaFragment = [NSString stringWithFormat:@" %@/%@ (%@; v%@)",
                [[loaded objectForInfoDictionaryKey:(id)kCFBundleNameKey] mme_stringByRemovingNonUserAgentTokenCharacters] ?: NSBundle.mme_mainBundle.bundlePath.lastPathComponent.stringByDeletingPathExtension.mme_stringByRemovingNonUserAgentTokenCharacters,
                loaded.mme_bundleVersionString.mme_stringByRemovingNonUserAgentTokenCharacters,
                loaded.bundleIdentifier.mme_stringByRemovingNonUserAgentTokenCharacters,
                [[loaded objectForInfoDictionaryKey:(id)kCFBundleVersionKey] mme_stringByRemovingNonUserAgentTokenCharacters]];
            userAgent = [userAgent stringByAppendingString:uaFragment];
        }
    });
    
    return userAgent;
}

- (NSString *)mme_legacyUserAgentString {
    NSString *legacyUAString = (NSString *)[self mme_objectForVolatileKey:MMELegacyUserAgent];
    if (!legacyUAString) {
        legacyUAString= [NSString stringWithFormat:@"%@/%@/%@ %@/%@",
            NSBundle.mme_mainBundle.bundleIdentifier.mme_stringByRemovingNonUserAgentTokenCharacters,
            NSBundle.mme_mainBundle.mme_bundleVersionString.mme_stringByRemovingNonUserAgentTokenCharacters,
            [[NSBundle.mme_mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey] mme_stringByRemovingNonUserAgentTokenCharacters],
            self.mme_legacyUserAgentBase.mme_stringByRemovingNonUserAgentTokenCharacters,
            self.mme_legacyHostSDKVersion.mme_stringByRemovingNonUserAgentTokenCharacters];
        [self mme_setObject:legacyUAString forVolatileKey:MMELegacyUserAgent];
    }
    return legacyUAString;
}

// MARK: - Update Configuration

- (nullable MMEDate *)mme_configUpdateDate {
    MMEDate *updateTime = (MMEDate *)[self mme_objectForVolatileKey:MMEConfigUpdateDate];
    if (!updateTime) { // try loading from the Persistent domain
        NSData *updateData = [self objectForKey:MMEConfigUpdateData];
        if (updateData) { // unarchive the data, saving the MMEDate in the volatile domain
            NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:updateData];
            unarchiver.requiresSecureCoding = YES;
            updateTime = [unarchiver decodeObjectOfClass:MMEDate.class forKey:NSKeyedArchiveRootObjectKey];
        } // else nil
    }
    return updateTime;
}

- (void)mme_setConfigUpdateDate:(nullable MMEDate *)updateTime {
    if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) {
        if (updateTime) {
            if (updateTime.timeIntervalSinceNow <= 0) { // updates always happen in the past
                NSKeyedArchiver *archiver = [NSKeyedArchiver new];
                archiver.requiresSecureCoding = YES;
                [archiver encodeObject:updateTime forKey:NSKeyedArchiveRootObjectKey];
                NSData *updateData = archiver.encodedData;
                [self mme_setObject:updateData forPersistentKey:MMEConfigUpdateData];
                [self mme_setObject:updateTime forVolatileKey:MMEConfigUpdateDate];
            }
            else NSLog(@"WARNING Mapbox Mobile Events Config Update Date cannot be set to a future date: %@", updateTime);
        }
    }
}

// MARK: - Location Collection

- (BOOL)mme_isCollectionEnabled {
    BOOL collectionEnabled = ![self boolForKey:MMECollectionDisabled];
    
#if TARGET_OS_SIMULATOR
    // disable collection in the simulator unless explicitly enabled for testing
    if (!self.mme_isCollectionEnabledInSimulator) {
        collectionEnabled = NO;
    }
#endif

    // if not explicitly disabled, or in simulator, check for low power mode
    if (@available(iOS 9.0, *)) {
        if (collectionEnabled && [NSProcessInfo instancesRespondToSelector:@selector(isLowPowerModeEnabled)]) {
                collectionEnabled = !NSProcessInfo.processInfo.isLowPowerModeEnabled;
        }
    }

    // Currently storage between App/Extension (AppGroup) is not shared meaning some values such as
    // privacy review consent are not shared between both. Default collection to OFF until shared support
    // is implemented
    if (NSBundle.mme_isExtension) {
        collectionEnabled = NO;
    }

    return collectionEnabled;
}

- (void)mme_setIsCollectionEnabled:(BOOL) collectionEnabled {
    [self mme_setObject:@(!collectionEnabled) forPersistentKey:MMECollectionDisabled];
}

- (BOOL)mme_isCollectionEnabledInSimulator {
    return [self boolForKey:MMECollectionEnabledInSimulator];
}

// MARK: - Background Collection

- (BOOL)mme_isCollectionEnabledInBackground {
    BOOL collectionEnabled = self.mme_isCollectionEnabled;
    if (collectionEnabled) { // check to see if it's seperately disabled
        id collectionDisabled = [self objectForKey:MMECollectionDisabledInBackground];
        if (collectionDisabled && [collectionDisabled isKindOfClass:NSNumber.class]) { //
            collectionEnabled = ![(NSNumber *)collectionDisabled boolValue];
        }
    }
    return collectionEnabled;
}

- (NSTimeInterval)mme_backgroundStartupDelay {
    return (NSTimeInterval)[self doubleForKey:MMEBackgroundStartupDelay];
}

-(CLLocationDistance)mme_backgroundGeofence {
    return (CLLocationDistance)[self doubleForKey:MMEBackgroundGeofence];
}

-(CLLocationAccuracy)mme_horizontalAccuracy {
    return (CLLocationAccuracy)[self doubleForKey:MMEHorizontalAccuracy];
}

// MARK: - Certificate Pinning and Revocation

- (NSArray<NSString *>*)mme_certificateRevocationList {
    NSArray<NSString *>* crl = @[];
    id crlObject = [self objectForKey:MMECertificateRevocationList];
    if ([crlObject isKindOfClass:NSArray.class]) {
        crl = (NSArray*)crlObject;
    }
    
    return crl;
}

/// The Certificate Pinning config
- (NSDictionary *)mme_certificatePinningConfig {
    NSMutableArray *comPublicKeys = @[
       // SHA1=0A:80:27:6E:1C:A6:5D:ED:1D:C2:24:E7:7D:0C:A7:24:0B:51:C8:54
       @"Tb0uHZ/KQjWh8N9+CZFLc4zx36LONQ55l6laDi1qtT4=",
       // SHA1=E2:8E:94:45:E0:B7:2F:28:62:D3:82:70:1F:C9:62:17:F2:9D:78:68
       @"yGp2XoimPmIK24X3bNV1IaK+HqvbGEgqar5nauDdC5E=",
       // SHA1=1A:62:1C:B8:1F:05:DD:02:A9:24:77:94:6C:B4:1B:53:BF:1D:73:6C
       @"BhynraKizavqoC5U26qgYuxLZst6pCu9J5stfL6RSYY=",
       // SHA1=20:CE:AB:72:3C:51:08:B2:8A:AA:AB:B9:EE:9A:9B:E8:FD:C5:7C:F6
       @"yJLOJQLNTPNSOh3Btyg9UA1icIoZZssWzG0UmVEJFfA=",
    ].mutableCopy;
    
    NSMutableArray *cnPublicKeys = @[
        // SHA1=5F:AB:D8:86:2E:7D:8D:F3:57:6B:D8:F2:F4:57:7B:71:41:90:E3:96
        @"3coVlMAEAYhOEJHgXwloiPDGaF+ZfxHZbVoK8AYYWVg=",
        // SHA1=1F:B8:6B:11:68:EC:74:31:54:06:2E:8C:9C:C5:B1:71:A4:B7:CC:B4
        @"5kJvNEMw0KjrCAu7eXY5HZdvyCS13BbA0VJG1RSP91w=",
        // SHA1=57:46:0E:82:B0:3F:E7:2C:AE:AC:CA:AF:2B:1D:DA:25:B4:B3:8A:4A
        @"+O+QJCmvoB/FkTd0/5FvmMSvFbMqjYU+Txrw1lyGkUQ=",
        // SHA1=7C:CC:2A:87:E3:94:9F:20:57:2B:18:48:29:80:50:5F:A9:0C:AC:3B
        @"zUIraRNo+4JoAYA7ROeWjARtIoN4rIEbCpfCRQT6N6A=",
    ].mutableCopy;
    
    // apply the CRL
    if (NSUserDefaults.mme_configuration.mme_certificateRevocationList) {
        [comPublicKeys removeObjectsInArray:NSUserDefaults.mme_configuration.mme_certificateRevocationList];
        [cnPublicKeys removeObjectsInArray:NSUserDefaults.mme_configuration.mme_certificateRevocationList];
    }
    
    return @{
        MMEEventsMapboxCom: comPublicKeys,
        MMEEventsMapboxCN: cnPublicKeys,
#if DEBUG
        MMEEventsTilestreamNet: @[@"f0eq9TvzcjRVgNZjisBA1sVrQ9b0pJA5ESWg6hVpK2c="]
#endif
    };
}

// MARK: - Configuration Service

- (NSError *)mme_updateFromConfigServiceData:(NSData *)configData {
    NSError *updateError = nil;
    if (configData) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:configData options:kNilOptions error:&updateError];
        if (json) {
            [self mme_updateFromConfigServiceObject:json updateError:&updateError];
        }
    }
    
    return updateError;
}

- (void)mme_updateFromAccountType:(NSInteger)typeCode {
    if (typeCode == MMEAccountType1) {
        [self mme_setObject:@(YES) forPersistentKey:MMECollectionDisabled];
    }
    else if (typeCode == MMEAccountType2) {
        [self mme_setObject:@(YES) forPersistentKey:MMECollectionDisabledInBackground];
    }
}

- (BOOL)mme_updateFromConfigServiceObject:(NSDictionary *)configDictionary updateError:(NSError **)updateError{
    BOOL success = NO;
    if (configDictionary) {
        if ([configDictionary.allKeys containsObject:MMERevokedCertKeys]) {
            NSError *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorConfigUpdateError userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Config object contains invalid key: %@", MMERevokedCertKeys]
            }];
            if (error && updateError) {
                *updateError = error;
            }
            return success;
        }

        id configCRL = [configDictionary objectForKey:MMEConfigCRLKey];
        if ([configCRL isKindOfClass:NSArray.class]) {
            for (NSString *publicKeyHash in configCRL) {
                NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:publicKeyHash options:(NSDataBase64DecodingOptions)0];
                if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){
                    NSError *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorConfigUpdateError userInfo:@{
                        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Hash value invalid: %@", pinnedKeyHash]
                    }];
                    if (error && updateError) {
                        *updateError = error;
                    }
                    return success;
                }
            }
            
            [self mme_setObject:configCRL forPersistentKey:MMECertificateRevocationList];
        }
        
        id configTTO = [configDictionary objectForKey:MMEConfigTTOKey];
        if ([configTTO isKindOfClass:NSNumber.class]) {
            [self mme_updateFromAccountType:[configTTO integerValue]];
        }
        
        id configGFO = [configDictionary objectForKey:MMEConfigGFOKey];
        if ([configGFO isKindOfClass:NSNumber.class]) {
            CLLocationDistance gfoDistance = [configGFO doubleValue];
            if (gfoDistance >= MMECustomGeofenceRadiusMinimum
             && gfoDistance <= MMECustomGeofenceRadiusMaximum) {
                [self mme_setObject:@(gfoDistance) forPersistentKey:MMEBackgroundGeofence];
            }
            else { // fallback to the default
                [self removeObjectForKey:MMEBackgroundGeofence];
            }
        }
        
        // `hao` config option for horizontal accuracy override. Possible values:
        // -1 - No HA Filter
        // 0 - Reset to Defaults, delete locally saved hao value in the prefs.
        // >0 - Maximum HA in Meters, saved to local preferences and used until the value reset or changed.
        id configHAO = [configDictionary objectForKey:MMEConfigHAOKey];
        if ([configHAO isKindOfClass:NSNumber.class]) {
            CLLocationDistance horizontalAccuracy = [configHAO doubleValue];
            if (horizontalAccuracy != 0) {
                [self mme_setObject:@(horizontalAccuracy) forPersistentKey:MMEHorizontalAccuracy];
            } else { // fallback to the default
                [self removeObjectForKey:MMEHorizontalAccuracy];
            }
        }

        id configBSO = [configDictionary objectForKey:MMEConfigBSOKey];
        if ([configBSO isKindOfClass:NSNumber.class]) {
            NSTimeInterval bsoInterval = [configBSO doubleValue];
            if (bsoInterval > 0 && bsoInterval <= MMEStartupDelayMaximum) {
                [self mme_setObject:@(bsoInterval) forPersistentKey:MMEBackgroundStartupDelay];
            }
        }
        
        id configTag = [configDictionary objectForKey:MMEConfigTagKey];
        if ([configTag isKindOfClass:NSString.class]) {
            [self mme_setObject:configTag forPersistentKey:MMEConfigEventTag];
        }
        
        success = YES;
    }
    return success;
}

@end

// MARK: -

@implementation NSBundle (MME)

static NSBundle *MMEMainBundle = nil;

+ (NSBundle *)mme_mainBundle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self mme_setMainBundle:nil];
    });
    return MMEMainBundle;
}

+ (void)mme_setMainBundle:(nullable NSBundle *)mainBundle {
    if (mainBundle) {
        MMEMainBundle = mainBundle;
    }
    else {
        MMEMainBundle = NSBundle.mainBundle;
    }
}

// MARK: -


- (NSString *)mme_bundleVersionString {
    NSString *bundleVersion = @"0.0.0";

    // check for MGLSemanticVersionString in Mapbox.framework
    if ([self.infoDictionary.allKeys containsObject:@"MGLSemanticVersionString"]) {
        bundleVersion = self.infoDictionary[@"MGLSemanticVersionString"];
        if (![bundleVersion mme_isSemverString]) { // issue a warning in debug builds
            NSLog(@"WARNING bundle %@ MGLSemanticVersionString string (%@) is not a valid semantic version string: http://semver.org", self, bundleVersion);
        }
    }
    else if ([self.infoDictionary.allKeys containsObject:@"CFBundleShortVersionString"]) {
        bundleVersion = self.infoDictionary[@"CFBundleShortVersionString"];
    }
    
    return bundleVersion;
}

@end

NS_ASSUME_NONNULL_END
