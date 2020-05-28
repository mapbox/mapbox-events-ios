#import "MMEPreferences.h"
#import "NSString+MMEVersions.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEConfig.h"
#import "MMELogger.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "NSBundle+MMEMobileEvents.h"

@interface MMEPreferences ()
@property (nonatomic, strong) NSBundle* bundle;
@property (nonatomic, strong) NSUserDefaults* userDefaults;
@end

@implementation MMEPreferences

// MARK: - Initializers

- (instancetype)init {
    return [self initWithBundle:NSBundle.mainBundle
                      dataStore:NSUserDefaults.mme_configuration];
}

-(instancetype)initWithBundle:(NSBundle*)bundle
                    dataStore:(NSUserDefaults*)userDefaults {
    self = [super init];
    if (self) {
        self.bundle = bundle;
        self.userDefaults = userDefaults;
        [self reset];
    }
    return self;
}

- (void)reset {
    [self.userDefaults setPersistentDomain:@{} forName:MMEConfigurationDomain];
    [self.userDefaults setVolatileDomain:@{} forName:MMEConfigurationVolatileDomain];

    id debugLoggingEnabled = [self.bundle objectForInfoDictionaryKey:MMEDebugLogging];
    if ([debugLoggingEnabled isKindOfClass:NSNumber.class]) {
        [MMELogger.sharedLogger setEnabled:[debugLoggingEnabled boolValue]];
    }

    id accountType = [self.bundle objectForInfoDictionaryKey:MMEAccountType];
    if ([accountType isKindOfClass:NSNumber.class]) {
        [self updateFromAccountType:[accountType integerValue]];
    }
}

// MARK: - Volitile Domain

- (NSDictionary *)volatileDomain {
    return [self.userDefaults volatileDomainForName:MMEConfigurationVolatileDomain] ?: NSDictionary.new;
}

- (void)setObject:(NSObject *)value forVolatileKey:(MMEVolatileKey *)key {
    NSMutableDictionary *volatileDomain = self.volatileDomain.mutableCopy;
    volatileDomain[key] = value;
    [self.userDefaults setVolatileDomain:volatileDomain forName:MMEConfigurationVolatileDomain];
}

- (nullable NSObject *)objectForVolatileKey:(MMEVolatileKey *)key {
    return self.volatileDomain[key];
}

- (void)deleteObjectForVolatileKey:(MMEVolatileKey *)key {
    NSMutableDictionary *volatileDomain = self.volatileDomain.mutableCopy;
    [volatileDomain removeObjectForKey:key];
    [self.userDefaults setVolatileDomain:volatileDomain forName:MMEConfigurationVolatileDomain];
}

// MARK: - Persistent Domain

- (NSDictionary*)persistentDomain {
    return [self.userDefaults persistentDomainForName:MMEConfigurationDomain] ?: NSDictionary.new;
}

- (void)setObject:(id)value forPersistentKey:(MMEPersistentKey *)key {
    NSMutableDictionary *domain = self.persistentDomain.mutableCopy;
    domain[key] = value;
    [self.userDefaults setPersistentDomain:domain forName:MMEConfigurationDomain];
}

- (void)deleteObjectForPersistentKey:(MMEPersistentKey *)key {
    NSMutableDictionary *domain = self.persistentDomain.mutableCopy;
    [domain removeObjectForKey:key];
    [self.userDefaults setPersistentDomain:domain forName:MMEConfigurationDomain];
}


// MARK: - Properties

- (NSTimeInterval)startupDelay {

    NSTimeInterval startupDelay = MMEStartupDelayDefault;

    // Then inspect for values in Bundle (only applicable if profile is set to custom)
    NSString *profileName = [self.bundle objectForInfoDictionaryKey:MMEEventsProfile];
    if ([profileName isEqualToString:MMECustomProfile]) {
        id startupDelayNumber = [self.bundle objectForInfoDictionaryKey:MMEStartupDelay];
        if ([startupDelayNumber isKindOfClass:NSNumber.class]) {
            NSTimeInterval infoDelay = [startupDelayNumber doubleValue];

            if (infoDelay > 0 && infoDelay <= MMEStartupDelayMaximum) {
                startupDelay = infoDelay;
            } else {
                NSLog(@"WARNING Mapbox Mobile Events Profile has invalid startup delay: %@", startupDelayNumber);
            }
        } else {
            NSLog(@"WARNING Mapbox Mobile Events Profile has invalid startup delay: %@", startupDelayNumber);
        }
    }

    return startupDelay;
}


- (NSUInteger)eventFlushCount {
    if ([self.userDefaults objectForKey:MMEEventFlushCount]) {
        return (NSUInteger)[[self.userDefaults objectForKey:MMEEventFlushCount] unsignedIntValue];
    } else {
        return MMEEventFlushCountDefault;
    }
}

-(void)setEventFlushCount:(NSUInteger)eventFlushCount {
    [self.userDefaults setInteger:eventFlushCount forKey:MMEEventFlushCount];
}

- (NSTimeInterval)eventFlushInterval {
    if ([self.userDefaults objectForKey:MMEEventFlushInterval]) {
        return (NSTimeInterval)[self.userDefaults doubleForKey:MMEEventFlushInterval];
    } else {
        return MMEEventFlushIntervalDefault;
    }
}

- (void)setEventFlushInterval:(NSTimeInterval)flushInterval {
    [self.userDefaults setDouble:flushInterval forKey:MMEEventFlushInterval];
}

- (NSTimeInterval)identifierRotationInterval {
    if ([self.userDefaults objectForKey:MMEIdentifierRotationInterval]) {
        return (NSTimeInterval)[self.userDefaults doubleForKey:MMEIdentifierRotationInterval];
    } else {
        return MMEIdentifierRotationIntervalDefault;
    }
}

- (void)setIdentifierRotationInterval:(NSTimeInterval)identifierRotationInterval {
    [self.userDefaults setDouble:identifierRotationInterval forKey:MMEIdentifierRotationInterval];
}

- (NSTimeInterval)configUpdateInterval {
    if ([self.userDefaults objectForKey:MMEConfigurationUpdateInterval]) {
        return [self.userDefaults doubleForKey:MMEConfigurationUpdateInterval];
    } else {
        return MMEConfigurationUpdateIntervalDefault;
    }
}

- (void)setConfigUpdateInterval:(NSTimeInterval)configUpdateInterval {
    [self.userDefaults setDouble:configUpdateInterval forKey:MMEConfigurationUpdateInterval];
}

- (nullable NSString *)eventTag {
    return [self.userDefaults stringForKey:MMEConfigEventTag];
}

- (void)setEventTag:(nullable NSString *)eventTag {
    if (eventTag) {
        [self setObject:[eventTag copy] forPersistentKey:MMEConfigEventTag];
    } else {
        [self.userDefaults removeObjectForKey:MMEConfigEventTag];
    }
}

- (nullable NSString*)accessToken {
    return (NSString*)[self objectForVolatileKey:MMEAccessToken];
}

- (void)setAccessToken:(NSString *)accessToken {
    [self setObject:accessToken forVolatileKey:MMEAccessToken];
}

- (NSString*)legacyUserAgentBase {
    if ([self objectForVolatileKey:MMELegacyUserAgentBase]) {
        return (NSString*)[self objectForVolatileKey:MMELegacyUserAgentBase];
    } else {
        id object = [self.bundle objectForInfoDictionaryKey:@"MMEMapboxUserAgentBase"];
        if ([object isKindOfClass:NSString.class]) {
            return (NSString*)object;
        }
    }
    return nil;
}

- (void)setLegacyUserAgentBase:(NSString *)legacyUserAgentBase {
    [self setObject:legacyUserAgentBase forVolatileKey:MMELegacyUserAgentBase];
    [self deleteObjectForVolatileKey:MMELegacyUserAgent];
}

- (NSString*)legacyHostSDKVersion {
    if ([self objectForVolatileKey:MMELegacyHostSDKVersion]) {
        return (NSString *)[self objectForVolatileKey:MMELegacyHostSDKVersion];
    } else {
        id object = [self.bundle objectForInfoDictionaryKey:@"MMEMapboxHostSDKVersion"];
        if ([object isKindOfClass:NSString.class]) {
            return (NSString*)object;
        }
    }
    return nil;
}

- (void)setLegacyHostSDKVersion:(NSString *)legacyHostSDKVersion {
    if (![legacyHostSDKVersion mme_isSemverString]) {
        NSLog(@"WARNING mme_setLegacyHostSDKVersion: version string (%@) is not a valid semantic version string: http://semver.org", legacyHostSDKVersion);
    }

    [self setObject:legacyHostSDKVersion forVolatileKey:MMELegacyHostSDKVersion];
    [self deleteObjectForVolatileKey:MMELegacyUserAgent];
}

- (NSString*)clientId {

    // Check for Existing Id
    NSString *clientId = [self.userDefaults stringForKey:MMEClientId];

    // Create new ID / Store
    if (!clientId) {
        clientId = NSUUID.UUID.UUIDString;
        [self setObject:clientId forPersistentKey:MMEClientId];
    }
    return clientId;
}

- (void)setClientId:(NSString *)clientId {
    [self setObject:clientId forPersistentKey:MMEClientId];
}

// MARK: - Service Configuration

- (BOOL)isChinaRegion {
    BOOL isChinaRegion = NO;

    id isCNRegionNumber = [self objectForVolatileKey:MMEIsCNRegion];
    if ([isCNRegionNumber isKindOfClass:NSNumber.class]) {
        isChinaRegion = [(NSNumber *)isCNRegionNumber boolValue];
    }

    id bundleAPIURL = [self.bundle objectForInfoDictionaryKey:MMEGLMapboxAPIBaseURL];
    if (bundleAPIURL) {
        isChinaRegion = [bundleAPIURL isEqual:MMEAPIClientBaseChinaAPIURL];
    }

    return isChinaRegion;
}

- (void)setIsChinaRegion:(BOOL)isChinaRegion {
    [self setObject:@(isChinaRegion) forVolatileKey:MMEIsCNRegion];
}

- (NSURL*)apiServiceURL {
    NSURL *serviceURL = nil;
    id infoPlistObject = [self.bundle objectForInfoDictionaryKey:MMEEventsServiceURL];

    if ([infoPlistObject isKindOfClass:NSURL.class]) {
        serviceURL = infoPlistObject;
    }
    else if ([infoPlistObject isKindOfClass:NSString.class]) {
        serviceURL = [NSURL URLWithString:infoPlistObject];
    }
    else if ([self isChinaRegion]) {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseChinaAPIURL];
    }
    else {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseAPIURL];
    }

    return serviceURL;
}

- (NSURL *)eventsServiceURL {
    NSURL *serviceURL = nil;
    id infoPlistObject = [self.bundle objectForInfoDictionaryKey:MMEEventsServiceURL];

    if ([infoPlistObject isKindOfClass:NSURL.class]) {
        serviceURL = infoPlistObject;
    }
    else if ([infoPlistObject isKindOfClass:NSString.class]) {
        serviceURL = [NSURL URLWithString:infoPlistObject];
    }
    else if ([self isChinaRegion]) {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseChinaEventsURL];
    }
    else {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseEventsURL];
    }

    return serviceURL;
}

- (NSURL*) configServiceURL {
    NSURL *serviceURL = nil;
    id infoPlistObject = [self.bundle objectForInfoDictionaryKey:MMEConfigServiceURL];

    if ([infoPlistObject isKindOfClass:NSURL.class]) {
        serviceURL = infoPlistObject;
    }
    else if ([infoPlistObject isKindOfClass:NSString.class]) {
        serviceURL = [NSURL URLWithString:infoPlistObject];
    }
    else if ([self isChinaRegion]) {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseChinaConfigURL];
    }
    else {
        serviceURL = [NSURL URLWithString:MMEAPIClientBaseConfigURL];
    }

    return serviceURL;
}

- (NSString *)userAgentString {
    static NSString *userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; v%@)",
                     self.bundle.infoDictionary[(id)kCFBundleNameKey],
                     self.bundle.mme_bundleVersionString,
                     self.bundle.bundleIdentifier,
                     self.bundle.infoDictionary[(id)kCFBundleVersionKey]];

        // check all loaded frameworks for mapbox frameworks, record thier bundleIdentifier
        NSMutableSet *loadedMapboxBundleIds = NSMutableSet.new;
        for (NSBundle *loaded in [NSBundle.allFrameworks arrayByAddingObjectsFromArray:NSBundle.allBundles]) {
            if (loaded.bundleIdentifier
                && loaded.bundleIdentifier != self.bundle.bundleIdentifier
                && [loaded.bundleIdentifier rangeOfString:@"mapbox" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [loadedMapboxBundleIds addObject:loaded.bundleIdentifier];
            }
        }

        // sort the bundleIdentifiers, then use them to build the User-Agent string
        NSArray *sortedBundleIds = [loadedMapboxBundleIds sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]]];
        for (NSString *bundleId in sortedBundleIds) {
            NSBundle *loaded = [NSBundle bundleWithIdentifier:bundleId];
            NSString *uaFragment = [NSString stringWithFormat:@" %@/%@ (%@; v%@)",
                                    loaded.infoDictionary[(id)kCFBundleNameKey],
                                    loaded.mme_bundleVersionString,
                                    loaded.bundleIdentifier,
                                    loaded.infoDictionary[(id)kCFBundleVersionKey]];
            userAgent = [userAgent stringByAppendingString:uaFragment];
        }
    });

    return userAgent;
}

- (NSString *)legacyUserAgentString {
    NSString *legacyUAString = (NSString *)[self objectForVolatileKey:MMELegacyUserAgent];

    // Provide Default Value
    if (!legacyUAString) {
        legacyUAString= [NSString stringWithFormat:@"%@/%@/%@ %@/%@",
                         self.bundle.bundleIdentifier,
                         self.bundle.mme_bundleVersionString,
                         [self.bundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey],
                         self.legacyUserAgentBase,
                         self.legacyHostSDKVersion];
        [self setObject:legacyUAString forVolatileKey:MMELegacyUserAgent];
    }

    return legacyUAString;
}

// MARK: - Update Configuration

- (nullable MMEDate *)configUpdateDate {
    MMEDate *updateTime = (MMEDate *)[self objectForVolatileKey:MMEConfigUpdateDate];
    if (!updateTime) { // try loading from the Persistent domain
        NSData *updateData = [self.userDefaults objectForKey:MMEConfigUpdateData];
        if (updateData) { // unarchive the data, saving the MMEDate in the volatile domain
            NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:updateData];
            unarchiver.requiresSecureCoding = YES;
            updateTime = [unarchiver decodeObjectOfClass:MMEDate.class forKey:NSKeyedArchiveRootObjectKey];
        } // else nil
    }
    return updateTime;
}

- (void)setConfigUpdateDate:(nullable MMEDate *)updateTime {
    if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) {
        if (updateTime) {
            if (updateTime.timeIntervalSinceNow <= 0) { // updates always happen in the past
                NSKeyedArchiver *archiver = [NSKeyedArchiver new];
                archiver.requiresSecureCoding = YES;
                [archiver encodeObject:updateTime forKey:NSKeyedArchiveRootObjectKey];
                NSData *updateData = archiver.encodedData;
                [self setObject:updateData forPersistentKey:MMEConfigUpdateData];
                [self setObject:updateTime forVolatileKey:MMEConfigUpdateDate];
            }
            else NSLog(@"WARNING Mapbox Mobile Events Config Update Date cannot be set to a future date: %@", updateTime);
        }
    }
}

// MARK: - Location Collection

- (BOOL)isCollectionEnabled {

    // Default Enable unless otherwise overridden
    BOOL collectionEnabled = YES;

#if TARGET_OS_SIMULATOR
    // Disable collection in the simulator unless explicitly enabled for testing
    if (!self.isCollectionEnabledInSimulator) {
        return NO;
    }
#endif

    // Inspect Overrides in NSUserDefaults
    id object = [self.userDefaults objectForKey:MMECollectionDisabled];
    if ([object isKindOfClass:NSNumber.class]){
        return ![(NSNumber*)object boolValue];
    }

    // Fallback to NSBundle
    id bundleObject = [self.bundle objectForInfoDictionaryKey:MMECollectionDisabled];
    if ([bundleObject isKindOfClass:NSNumber.class]) {
        return ![(NSNumber*)bundleObject boolValue];
    }

    // If not explicitly disabled, or in simulator, check for low power mode
    if (@available(iOS 9.0, *)) {
        if (collectionEnabled && [NSProcessInfo instancesRespondToSelector:@selector(isLowPowerModeEnabled)]) {
            return !NSProcessInfo.processInfo.isLowPowerModeEnabled;
        }
    }

    return collectionEnabled;
}

- (void)setIsCollectionEnabled:(BOOL) isCollectionEnabled {
    [self setObject:@(!isCollectionEnabled) forPersistentKey:MMECollectionDisabled];
}

- (BOOL)isCollectionEnabledInSimulator {

    BOOL isCollectionEnabledInSimulator = false;

    // Inspect for NSUserDefault Overrides
    id object = [self.userDefaults objectForKey:MMECollectionEnabledInSimulator];
    if ([object isKindOfClass:NSNumber.class]) {
        return [(NSNumber*)object boolValue];
    }

    // Fall Back to Info.Plist
    id bundleObject = [self.bundle objectForInfoDictionaryKey:MMECollectionEnabledInSimulator];
    if ([bundleObject isKindOfClass:NSNumber.class]) {
        return [(NSNumber*)bundleObject boolValue];
    }

    return isCollectionEnabledInSimulator;
}

// MARK: - Background Collection

- (BOOL)isCollectionEnabledInBackground {
    BOOL collectionEnabled = self.isCollectionEnabled;

    // If Collection is disabled, background collection is automatically disabled
    if (!self.isCollectionEnabled) {
        return NO;
    }

    // Inspect for UserDefault Override
    id collectionDisabled = [self.userDefaults objectForKey:MMECollectionDisabledInBackground];
    if (collectionDisabled && [collectionDisabled isKindOfClass:NSNumber.class]) {
        return ![(NSNumber *)collectionDisabled boolValue];
    }

    // If no UserDefault Overide, Check for Definition in bundle
    id infoCollectionEnabledInSimulator = [self.bundle objectForInfoDictionaryKey:MMECollectionEnabledInSimulator];
    if ([infoCollectionEnabledInSimulator isKindOfClass:NSNumber.class]) {
        return [(NSNumber*)infoCollectionEnabledInSimulator boolValue];
    }

    return collectionEnabled;
}

- (void)setIsCollectionEnabledInBackground:(BOOL)isCollectionEnabledInBackground {
    [self setObject:@(!isCollectionEnabledInBackground) forPersistentKey:MMECollectionDisabledInBackground];
}

- (NSTimeInterval)backgroundStartupDelay {

    // Default Value
    NSTimeInterval startupDelay = MMEBackgroundStartupDelayDefault;

    // Override Provided by UserDefaults
    id value = [self.userDefaults objectForKey:MMEBackgroundStartupDelay];
    if ([value isKindOfClass:NSNumber.class]){
        return ((NSNumber*)value).doubleValue;
    }

    return startupDelay;
}

- (void)setBackgroundStartupDelay:(NSTimeInterval)backgroundStartupDelay {
    [self.userDefaults setDouble:backgroundStartupDelay forKey:MMEBackgroundStartupDelay];
}

-(CLLocationDistance)backgroundGeofence {
    CLLocationDistance backgroundGeofence = MMEBackgroundGeofenceDefault;

    // Inspect for local overrides
    id radius = [self.userDefaults objectForKey:MMEBackgroundGeofence];
    if ([radius isKindOfClass: NSNumber.class]) {
        CLLocationDistance infoGeofence = [radius doubleValue];

        if (infoGeofence >= MMECustomGeofenceRadiusMinimum
            && infoGeofence <= MMECustomGeofenceRadiusMaximum) {
            backgroundGeofence = infoGeofence;
        } else {
            NSLog(@"WARNING Mapbox Mobile Events Profile has invalid geofence radius: %@", radius);
        }

        return infoGeofence;
    }

//        NSString *profileName = (NSString*)[NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEEventsProfile];
//        if ([profileName isEqualToString:MMECustomProfile]) {
    //        id customRadiusNumber = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMECustomGeofenceRadius];
    //        if ([customRadiusNumber isKindOfClass:NSNumber.class]) {
    //            CLLocationDistance infoGeofence = [customRadiusNumber doubleValue];
    //
    //            if (infoGeofence >= MMECustomGeofenceRadiusMinimum
    //             && infoGeofence <= MMECustomGeofenceRadiusMaximum) {
    //                backgroundGeofence = infoGeofence;
    //            }
    //            else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid geofence radius: %@", customRadiusNumber);
    //        }
    //        else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid geofence: %@", customRadiusNumber);
    //
    //        id startupDelayNumber = [NSBundle.mme_mainBundle objectForInfoDictionaryKey:MMEStartupDelay];
    //        if ([startupDelayNumber isKindOfClass:NSNumber.class]) {
    //            NSTimeInterval infoDelay = [startupDelayNumber doubleValue];
    //
    //            if (infoDelay > 0 && infoDelay <= MMEStartupDelayMaximum) {
    //                startupDelay = infoDelay;
    //            }
    //            else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid startup delay: %@", startupDelayNumber);
    //        }
    //        else NSLog(@"WARNING Mapbox Mobile Events Profile has invalid startup delay: %@", startupDelayNumber);
    //    }

    // Then inspect for values in Bundle (only applicable if profile is set to custom)
    NSString *profileName = [self.bundle objectForInfoDictionaryKey:MMEEventsProfile];
    if ([profileName isEqualToString:MMECustomProfile]) {
        id radiusNumber = [self.bundle objectForInfoDictionaryKey:MMECustomGeofenceRadius];
        if ([radiusNumber isKindOfClass:NSNumber.class]) {
            CLLocationDistance infoGeofence = [radiusNumber doubleValue];

            if (infoGeofence >= MMECustomGeofenceRadiusMinimum
                && infoGeofence <= MMECustomGeofenceRadiusMaximum) {
                backgroundGeofence = infoGeofence;
            } else {
                NSLog(@"WARNING Mapbox Mobile Events Profile has invalid geofence radius: %@", radiusNumber);
            }
        }
    }


    // Otherwise use default
    return backgroundGeofence;
}

// MARK: - Certificate Pinning and Revocation

-(NSArray<NSString*>*)certificateRevocationList {

    // Default List
    NSArray<NSString *>* certificateRevocationList = @[];

    // Inspect UserDefault Overrides
    id object = [self.userDefaults objectForKey:MMECertificateRevocationList];
    if ([object isKindOfClass:NSArray.class]) {
        return (NSArray*)object;
    }

    // If UserDefault isn't provided, fallback to Bundle Definition
    object = [self.bundle objectForInfoDictionaryKey:MMECertificateRevocationList];
    if ([object isKindOfClass:NSArray.class]) {
        return (NSArray*)object;
    }

    return certificateRevocationList;
}

-(void)setCertificateRevocationList:(NSArray<NSString *> * _Nonnull)certificateRevocationList {
    [self setObject:certificateRevocationList forPersistentKey:MMECertificateRevocationList];
}

- (NSMutableArray<NSString*>*)comPublicKeys {
    return @[
        @"T4XyKSRwZ5icOqGmJUXiDYGa+SaXKTGQXZwhqpwNTEo=",
        @"KlV7emqpeM6V2MtDEzSDzcIob6VwkdWHiVsNQQzTIeo=",
        @"16TK3iq9ZB4AukmDemjUyhcPTUnsSuqd5OB5zOrheZY=",
        @"F16cPFncMDkB4XbRfK64H1dqncNg6JOdd+w2qElR/hM=",
        @"45PQwWtFAHQd/cVzMVuhkwOQwCF+JE4ZViA4gkzvWeQ=",
        @"mCzfopN5vqaerktI/172w8T7qw2sfRXgUL4Z7xA2e/c=",
        @"rFFCqIOOKu7KH1v73IHb6mzZQth7cVvVDaH+EjkNfKM=",
        @"pZBpEiH9vLwSICbogdpgyGG3NCjVKw4oG2rEWRf03Vk=",
        @"gPgpSOzaLjbIpDLlh302x2irQTzWfsQqIWhUsreMMzI=",
        @"wLHqvUDDQfFymRVS2O6AF5nkuAY+KJZpI4+pohK+SUE=",
        @"yAEZR9ydeTrMlcUp91PHdmJ3lBa86IWsKRwiM0KzS6Q=",
        @"k3NZbP68SikfwacfWDm4s3YJDsPVWJSOF4GlCWo5RJA=",
        @"1PRG2KOhfDE+xMS1fxft5CtQO99mzqhpl4gPz/64IxQ=",
        @"FBibSsaWfYYIkij1x4Oc9Lt0jHl+6AhBTWAypcOphhc=",
        @"X0K6GmWp00Pb0YATdlCPeXaZR/NxxHTv41OAEkymkbU=",
        @"DU/+Q9Itbb4WuSfuTvOgPtxtF6eAbTH7pUFn17/o5E0=",
        @"BYGHyEqtaJEZn+02i4jy4dGRRFNr6xckQjTL7DMZFes=",
        @"zr1/pj8y4FUbrxIYRaHVZWvhsMPzDVW0R+ljPHrX5Sw=",
        @"fS9IR9OWsirEnSAqParPG0BzZJ+Dk4CiHfPv1vEjrf0=",
        @"f1B7KmHknBSXNjTC8ac/Hf7hwU2goerE53TJppr0OH0=",
        @"OKbbVU/+cTlszrJkxKaQraFAoVyjPOqa5Uq8Ndd4AUg=",
        @"I0xGZF5s9kGHJHz6nKN+nYJKwf8ev1MdWkGt7EI7A7g=",
        @"anATIIIqUd4o7Asto7X7OEJ+m7YTUr0aJKHZXqL92w0=",
        @"JXFJ+lQK4GwJpJlHSZ2ZAR5luZDwMdaa2hJyhqHc1L8=",
        @"64k4IzkPceL/hQywCCvJLQds8FPMPwtclhFOR/taKAQ=",
        @"c079Pt5XXCwSv+pROEF+YW5gRoyzJ248bPxVLrUYkHM=",
        @"46ofOPUGR3SYcMB+MmXqowYKan/c18LBTV2sAk13WKc=",
        @"4qwz7KaBHxEX+YxO8STVowTg2BxlOd98GNU5feRjdjU=",
        @"hp54/fY89ziuBBp1zv3YaC8H9/G8/Xp97hdzRVdcqQ0=",
        @"BliQkuPecuHEp3FN3r1HogAkmsLtZz3ZImqLSpJoJzs=",
        @"GayCH1YATG/OS5h1bq79XRmcq/aqwoObu2OYfPN7vQc=",
        @"fW6I4HEBwa1Pwi1dldkb+ljs4re5ZY2JbsCiCxCOCgI=",
        @"GcqilfT04N2efVIWlzJWO04gdpwYC4sLnOx3TJIKA9E=",
        @"+1CHLRDE6ehp61cm8+NDMvd32z0Qc4bgnZRLH0OjE94=",
        @"4vJWNxtoMLAY35dbzKeDI+4IAFOW97WNkTWnNMtY5TA=",
        @"1YjWX9tieIA1iGkJhm7UapH6PiwGViZBWrXA3UJUAWc=",
        @"X+RKpA7gtptrZ9yI1C96Isw5RV8dQyx5z7I/xfCaBl8=",
        @"hqFsdAuHVvjX3NuaUBVZao94V30SdXLAsG1O0ajgixw=",
        @"wYl9ZFQd2LWKfjDuEQxo7S0CcrPkP9A3vb20fbHf1ZQ=",
        @"Y3ax6OgoQkcStQZ2hrIAqMDbaEEwX6xZfMZEnVcn/4k=",
        @"taSOM7qPorxZ64Whrl5ZiNCGlZqLrVPOIBwPr/Nkw6U=",
        @"KB5X/PyAAiRc7W/NjUyd6xbDdibuOTWBJB2MqHHF/Ao=",
        @"hRQ7yTW/P5l76uNNP3MXNgshlmcbDNHMtBxCbUtGAWE=",
        @"AoclhkrtKF+qHKKq0wUS4oXLwlJtWlywtiLndnNzS2U=",
        @"5ikvGB5KkNlwesHRqjYvkZGlxP6OLMbaCkpflTM4DNM=",
        @"qK2GksTrZ7LXDBkNWH6FnuNGxgxPpwNSK+NgknU7H1U=",
        @"K3qyQniCBiGmfutYDE7ryDY2YoTORgp4DOgK1laOqfo=",
        @"B7quINbFSUen02LQ9kwtYXnsJtixTpKafzXFkcRb7RU=",
        @"Kc7lrHTlRfLaeRaEof6mKKmBH2eYHMYkxOy3yGlzUWg=",
        @"7s1BUHi/AW/beA2jXamNTUgbDMH4gVPR9diIhnN1o0Q=",
        //Digicert, 2018, SHA1 Fingerprint=5F:AB:D8:86:2E:7D:8D:F3:57:6B:D8:F2:F4:57:7B:71:41:90:E3:96
        @"3coVlMAEAYhOEJHgXwloiPDGaF+ZfxHZbVoK8AYYWVg=",
        //Digicert, 2018, SHA1 Fingerprint=1F:B8:6B:11:68:EC:74:31:54:06:2E:8C:9C:C5:B1:71:A4:B7:CC:B4
        @"5kJvNEMw0KjrCAu7eXY5HZdvyCS13BbA0VJG1RSP91w=",
        //GeoTrust, 2018, SHA1 Fingerprint=57:46:0E:82:B0:3F:E7:2C:AE:AC:CA:AF:2B:1D:DA:25:B4:B3:8A:4A
        @"+O+QJCmvoB/FkTd0/5FvmMSvFbMqjYU+Txrw1lyGkUQ=",
        //GeoTrust, 2018, SHA1 Fingerprint=7C:CC:2A:87:E3:94:9F:20:57:2B:18:48:29:80:50:5F:A9:0C:AC:3B
        @"zUIraRNo+4JoAYA7ROeWjARtIoN4rIEbCpfCRQT6N6A=",
    ].mutableCopy;
}

-(NSMutableArray<NSString*>*)chinaPublicKeys {
    return @[
        @"6+ErFga5JfYfvwx2JbEJJNmUXJFnXIKllrbPKmvWqNc=",
        @"vLkrnr8JTAVaYPwY/jBkKCe+YQWleaHPU3Tlqom+gCg=",
        @"UofZo86l1bDjTiHyKXurqgfkYaYjtjyTrOYYR68XLG8=",
        @"wSE/ahOwDVj7tMLMOjoAr1gIoBoWrUhQOBliQ82/bGk=",
        @"RKHNDCiwHVTR5vKksBOcpfaojpsfCMFQ9MAE01ac8Tk=",
        @"enUlaLivnHjrJBFVcvr8gwVTVcjXWOv8n96jU5towo8=",
        @"Cul962ner+uZmwBQybZi0CHlFiZ3uFnZJe/lKqnqL6k=",
        @"WswAtgVhFf6bIpavbiBL2GOP+e/zWqnECQrK17qKOLU=",
        @"O+4Y2hugHTXgiaf6s2Zt4Vc7M3l3lLLu+6ugYGLI1x0=",
        @"tfeXXd8OZXRbuZgeOanQAsgQlgdh4GBIIyCDvULtwLA=",
        @"A+vWP93KGIMHeADZtj9S/mSIQtvzGz5G671aRKf3NlY=",
        @"malXG7/2Qay6uSfQxLGm2Lob8MVjSPkzNrtdnwpHhuA=",
        @"zfBsiWe9eHeGevBcYtrGiPQ0zCr2IvB08S7ESSWqVN8=",
        @"o8bx+G1dysezoWAvOXBsl4/E6LcABFSqy6J8si5Cryk=",
        @"YrsgZS2RzrUtunIndi031Ye/HyMn7WQQweav4xgR6qk=",
        @"HQqyJQU7b+X/v1297LXK4TxKMwdC72Qzqy7Jx5W3LgA=",
        @"00lmpHvG3dPLQ/hsewpHNLsK9vruPV+0hcQAl7FmRxI=",
        @"lrmOBGfUptzfKOgSLUCKRvhfYNLH94x2ZKaX5ijBbTs=",
        @"nf4V9/G5BE3bNy7TDkvqc7MaIkfcA625hjtQM7FJkcM=",
        @"/0K/iJYfENe5o5arEhWfT7sailUd/QBY3ws0wD9dggU=",
        @"SDnReAbazEH28n7pV5M/8A0M8ggJrO8/teE7oCJ7OGU=",
        @"gruIKpo+vo5XKJ8t6yoPeNrpjWSsdnyaxkSLe/vSz2U=",
        @"a4CTRze+fw6iUhnKA7Ph2Qt41eco42RBFcHITnYcNoY=",
        @"8wc+3VCcufdq1JzdsxtaleFLA/u/peBtjfdPOeFKsIo=",
        @"a5foMaNKMbLYMnB079u3G2oxhSRSHilwljENMsBiQwE=",
        @"r1t+lUCzuncTnfM/QtclWIA7zhN8AYYUWlIimDhI0HM=",
        @"dFS5RaEoQf7naXnfYnP1AuQMxyJwygHAXRG4bOZD6OM=",
        @"zSAUiJZbnZdUu2bKUNf21r7RXJPzHGuMFxwPx7aLhfg=",
        @"UmlVTDcbkUR075i+thE9Q1fOxPIGn8PmQ51R+XL4fK8=",
        @"Zx+aoQE1cmiSN1TwvCo1Qpvuwjbq35eH4DsmkXKacIo=",
        @"TAOftRoKGrOsFjgCtUzHswja6MykOf9UZaoljB6TYso=",
        @"tW+psPLgOjPSsSMZPxc/PDGw0vBIpIZz32av4NEzVjc=",
        @"35zTxuHmPcNqJ5OSW02V+9ghV3TJYmBI3arMTuC1z9w=",
        @"ciiuiChtsyaTUEkDZ/N1KJaAgr4bIAIM13R0B9NVt6M=",
        @"cwUwdyqZ6YOMWX5zcJcYarQ5okvMLxj/Rd4dUpkRFHM=",
        @"tShTLeS4OltlKlE3MQUvXlJsGrCFgFo/nXvl5t0qba8=",
        @"qy6BTLAetvqNOFfT/M3pZSRo9FRaF8KudDGgHy8Fxis=",
        @"AOOutVCG4tDUsn13XyTAsx3cTZtIGajdCxSJoGZ+jp4=",
        @"0LqMhNP7UHpAVl6+ON7AzsqeMWZb1ElB5AL0kPS6ktI=",
        @"Zqng4S5spV0NeKT8MrE8CJFMBTP188PG9iEi7/9HDyo=",
        @"i/4rsupujT8Ww/2yIGJ3wb6R7GDw2FHPyOM5sWh87DQ=",
        @"cvlddgcP0XDOIKnCr+h+2zy2Tt8pnCPdw1l+PiEyS5o=",
        @"UhpcxVytZbC4dx2Dnjjg6k02Ylf5jLo3C3AxchaKhh0=",
        @"ZJfLxFuRg/1giSVrnj6aZmU5T//PP2eU7NLXXeqdH7s=",
        @"ZnL4xB/aLV5W0YSZVefBRZSRTeoLzjJkk7CBvz75/m8=",
        @"d4GNs3j9rUym4ogDTWX7AXTaI3K3gt46S2tvL6Hh/bQ=",
        @"R9Wa2ON8VRWRF5OyDDaSDMhf7ysK1ykV1XSq20RMDFM=",
        @"QMMBDJh3g1QgkGV6m+T4i2weBGj/W2+fVG73slK3mJE=",
        @"ENU8M1yItdL5EP0G+I4hz4iuGlAUIHWCe4ipwXB/c/A=",
        @"PA1lecwXNRXY/Vpy0VN+jQEYChN4hCAF36oB0Ygx3wQ=",
        // Digicert, 2016, SHA1 Fingerprint=0A:80:27:6E:1C:A6:5D:ED:1D:C2:24:E7:7D:0C:A7:24:0B:51:C8:54
        @"Tb0uHZ/KQjWh8N9+CZFLc4zx36LONQ55l6laDi1qtT4=",
        // Digicert, 2017, SHA1 Fingerprint=E2:8E:94:45:E0:B7:2F:28:62:D3:82:70:1F:C9:62:17:F2:9D:78:68
        @"yGp2XoimPmIK24X3bNV1IaK+HqvbGEgqar5nauDdC5E=",
        // Geotrust, 2016, SHA1 Fingerprint=1A:62:1C:B8:1F:05:DD:02:A9:24:77:94:6C:B4:1B:53:BF:1D:73:6C
        @"BhynraKizavqoC5U26qgYuxLZst6pCu9J5stfL6RSYY=",
        // Geotrust, 2017, SHA1 Fingerprint=20:CE:AB:72:3C:51:08:B2:8A:AA:AB:B9:EE:9A:9B:E8:FD:C5:7C:F6
        @"yJLOJQLNTPNSOh3Btyg9UA1icIoZZssWzG0UmVEJFfA=",
    ].mutableCopy;
}

-(NSDictionary<NSString*, NSArray<NSString*>*>*)certificatePinningConfig {
    NSMutableArray *comPublicKeys = [self comPublicKeys];
    NSMutableArray *chinaPublicKeys = [self chinaPublicKeys];

    // Filter out Revoked Keys
    if (self.certificateRevocationList){
        [comPublicKeys removeObjectsInArray:self.certificateRevocationList];
        [chinaPublicKeys removeObjectsInArray:self.certificateRevocationList];
    }

    // Construct Dictionary
    return @{
        MMEEventsMapboxCom: comPublicKeys,
        MMEEventsMapboxCN:  chinaPublicKeys,
#if DEBUG
        MMEEventsTilestreamNet: @[@"f0eq9TvzcjRVgNZjisBA1sVrQ9b0pJA5ESWg6hVpK2c="]
#endif
    };
}

// MARK: - Updates

- (void)updateFromAccountType:(NSInteger)typeCode {
    if (typeCode == MMEAccountType1) {

        // TDOO: Should this be mutating this value? Or blocking it from being turned on?
        self.isCollectionEnabled = NO;
    }
    else if (typeCode == MMEAccountType2) {

        // TDOO: Should this be mutating this value? Or blocking it from being turned on?
        self.isCollectionEnabledInBackground = NO;
    }
}

- (void)updateWithConfig:(MMEConfig*)config {

    self.certificateRevocationList = config.certificateRevocationList;

    if (config.telemetryTypeOverride) {
        [self updateFromAccountType:[config.telemetryTypeOverride integerValue]];
    }

    if (config.geofenceOverride) {
        [self setObject:config.geofenceOverride forPersistentKey:MMEBackgroundGeofence];
    } else {
        // fallback to the default
        [self.userDefaults removeObjectForKey:MMEBackgroundGeofence];
    }

    if (config.backgroundStartupOverride) {
        self.backgroundStartupDelay = (NSTimeInterval)[config.backgroundStartupOverride doubleValue];
    }

    if (config.eventTag) {
        self.eventTag = config.eventTag;
    }
}

@end
