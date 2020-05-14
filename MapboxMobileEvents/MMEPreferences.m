#import "MMEPreferences.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "NSString+MMEVersions.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEConfig.h"
#import "MMELogger.h"

// TODO: Consider moving these constant Definitions
#import "NSUserDefaults+MMEConfiguration_Private.h"


@interface MMEPreferences ()
@property (nonatomic, strong) NSBundle* bundle;
@property (nonatomic, strong) NSUserDefaults* userDefaults;
@end

@implementation MMEPreferences

// MARK: - Initializers

- (instancetype)init {
    return [self initWithBundle:NSBundle.mainBundle
                      dataStore:[[NSUserDefaults alloc] init]];
}

-(instancetype)initWithBundle:(NSBundle*)bundle
                    dataStore:(NSUserDefaults*)userDefaults {
    self = [super init];
    if (self) {
        self.bundle = bundle;
        self.userDefaults = userDefaults;
    }
    return self;
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

- (void)setFlushInterval:(NSTimeInterval)flushInterval {
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
    // Is there a default here?
    return (NSString*)[self objectForVolatileKey:MMEAccessToken];
}

- (void)setLegacyUserAgentBase:(NSString *)legacyUserAgentBase {
    // TODO: Why does this delete user agent?
    [self setObject:legacyUserAgentBase forVolatileKey:MMELegacyUserAgentBase];
    [self deleteObjectForVolatileKey:MMELegacyUserAgent];
}

- (NSString*)legacyHostSDKVersion {
    return (NSString *)[self objectForVolatileKey:MMELegacyHostSDKVersion];
}

- (void)setLegacyHostSDKVersion:(NSString *)legacyHostSDKVersion {
    if (![legacyHostSDKVersion mme_isSemverString]) {
        NSLog(@"WARNING mme_setLegacyHostSDKVersion: version string (%@) is not a valid semantic version string: http://semver.org", legacyHostSDKVersion);
    }

    // TODO: Why is this deleting another key?
    [self setObject:legacyHostSDKVersion forVolatileKey:MMELegacyHostSDKVersion];
    [self deleteObjectForVolatileKey:MMELegacyUserAgent];
}

- (NSString*)clientId {
    NSString *clientId = [self.userDefaults stringForKey:MMEClientId];
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
    BOOL isCNRegion = NO;
    id isCNRegionNumber = [self objectForVolatileKey:MMEIsCNRegion];

    if ([isCNRegionNumber isKindOfClass:NSNumber.class]) {
        isCNRegion = [(NSNumber *)isCNRegionNumber boolValue];
    }

    return isCNRegion;
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
                         NSBundle.mme_mainBundle.bundleIdentifier,
                         NSBundle.mme_mainBundle.mme_bundleVersionString,
                         [NSBundle.mme_mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey],
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

    // By inverting this value, we default to collection enabled
    BOOL collectionEnabled = ![self.userDefaults boolForKey:MMECollectionDisabled];

#if TARGET_OS_SIMULATOR
    // disable collection in the simulator unless explicitly enabled for testing
    if (!self.isCollectionEnabledInSimulator) {
        collectionEnabled = NO;
    }
#endif

    // if not explicitly disabled, or in simulator, check for low power mode
    if (@available(iOS 9.0, *)) {
        if (collectionEnabled && [NSProcessInfo instancesRespondToSelector:@selector(isLowPowerModeEnabled)]) {
            collectionEnabled = !NSProcessInfo.processInfo.isLowPowerModeEnabled;
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
        return [object boolValue];
    }

    // Fall Back to Info.Plist
    id bundleObject = [self.bundle objectForInfoDictionaryKey:MMECollectionEnabledInSimulator];
    if ([bundleObject isKindOfClass:NSNumber.class]) {
        isCollectionEnabledInSimulator = [bundleObject boolValue];
        return isCollectionEnabledInSimulator;
    }

    return isCollectionEnabledInSimulator;
}

// MARK: - Background Collection

- (BOOL)isCollectionEnabledInBackground {
    BOOL collectionEnabled = self.isCollectionEnabled;
    if (collectionEnabled) { // check to see if it's seperately disabled
        id collectionDisabled = [self.userDefaults objectForKey:MMECollectionDisabledInBackground];
        if (collectionDisabled && [collectionDisabled isKindOfClass:NSNumber.class]) { //
            collectionEnabled = ![(NSNumber *)collectionDisabled boolValue];
        }
    }
    return collectionEnabled;
}

- (NSTimeInterval)backgroundStartupDelay {
    return (NSTimeInterval)[self.userDefaults doubleForKey:MMEBackgroundStartupDelay];
}

- (void)setBackgroundStartupDelay:(NSTimeInterval)backgroundStartupDelay {
    [self.userDefaults setDouble:backgroundStartupDelay forKey:MMEBackgroundStartupDelay];
}

-(CLLocationDistance)backgroundGeofence {
    CLLocationDistance backgroundGeofence = MMEBackgroundGeofenceDefault;

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
    return backgroundGeofence;
}

// MARK: - Certificate Pinning and Revocation

-(NSArray<NSString*>*)certificateRevocationList {

    NSArray<NSString *>* certificateRevocationList = @[];
    id object = [self.userDefaults objectForKey:MMECertificateRevocationList];
    if ([object isKindOfClass:NSArray.class]) {
        certificateRevocationList = (NSArray*)object;
    }

    return certificateRevocationList;
}

-(void)setCertificateRevocationList:(NSArray<NSString *> * _Nonnull)certificateRevocationList {
    [self setObject:certificateRevocationList forPersistentKey:MMECertificateRevocationList];
}

-(NSDictionary<NSString*, NSArray<NSString*>*>*)certificatePinningConfig {
    NSMutableArray *comPublicKeys = [NSUserDefaults comPublicKeys];
    NSMutableArray *chinaPublicKeys = [NSUserDefaults chinaPublicKeys];

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
        [self setObject:@(YES) forPersistentKey:MMECollectionDisabled];
    }
    else if (typeCode == MMEAccountType2) {
        [self setObject:@(YES) forPersistentKey:MMECollectionDisabledInBackground];
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
