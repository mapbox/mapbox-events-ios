#import <CommonCrypto/CommonDigest.h>

#import "MMEEvent.h"

#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEvent+SystemInfo.h"
#import "MMEEventsManager.h"
#import "MMEReachability.h"

#import "NSUserDefaults+MMEConfiguration.h"
#if TARGET_OS_IOS || TARGET_OS_TVOS
#import "UIKit+MMEMobileEvents.h"
#endif


@interface MMEEvent ()
@property(nonatomic) MMEDate *dateStorage;
@property(nonatomic) NSDictionary *attributesStorage;

@end

// MARK: -

@implementation MMEEvent

+ (NSDictionary *)nilAttributes {
    static NSDictionary *nilAttributes = nil;
    if (!nilAttributes) {
        nilAttributes = @{};
    }
    return nilAttributes;
}

+ (NSString *)redactedStackFrame:(NSString*)stackFrame {
    static NSArray<NSRegularExpression *>* allowedSymbols = nil;
    if (!allowedSymbols) {
        allowedSymbols = @[
            [NSRegularExpression regularExpressionWithPattern:@"CoreFoundation" options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:@"GraphicsServices" options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:@"Foundation" options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:@"libobjc" options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:@"libdyld.dylib" options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:@"Mapbox" options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:@"MME" options:0 error:nil]
        ];
    }

    BOOL shouldRedact = YES;
    NSRange frameRange = NSMakeRange(0, stackFrame.length);

    // check for each allowed symbol, if we find one then the redacted frame is
    for (NSRegularExpression *expression in allowedSymbols) {
        if ([expression numberOfMatchesInString:stackFrame options:0 range:frameRange]) {
            shouldRedact = NO;
            break; // for
        }
    }

    return (shouldRedact ? @"-\redacted" : stackFrame);
}

// MARK: - Generic Events

+ (instancetype)eventWithAttributes:(NSDictionary *)attributes {
    NSError *eventError = nil;
    MMEEvent *newEvent = [self eventWithAttributes:attributes error:&eventError];
    if (eventError != nil) {
        [MMEEventsManager.sharedManager reportError:eventError];
    }

    return newEvent;
}

+ (instancetype)eventWithAttributes:(NSDictionary *)attributes error:(NSError **)error {
    return [self.alloc initWithAttributes:attributes error:error];
}

// MARK: - Custom Events

+ (instancetype)turnstileEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeAppUserTurnstile;

    return [self eventWithAttributes:eventAttributes];
}

+ (instancetype)visitEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeVisit;

    return [self eventWithAttributes:eventAttributes];
}

// MARK: - Error Events

+ (instancetype)errorEventReporting:(NSError *)eventsError error:(NSError **)createError {
    // start with common event data
    NSMutableDictionary *errorAttributes = NSMutableDictionary.new;
    errorAttributes[MMEEventKeyEvent] = MMEEventMobileCrash;
#if DEBUG
    errorAttributes[MMEEventKeyBuildType] = @"debug";
#else
    errorAttributes[MMEEventKeyBuildType] = @"release";
#endif
    errorAttributes[MMEEventKeyIsSilentCrash] = @"yes";
    errorAttributes[MMEEventSDKIdentifier] = NSUserDefaults.mme_configuration.mme_userAgentString;
    errorAttributes[MMEEventKeyAppID] = (NSBundle.mainBundle.bundleIdentifier ?: @"unknown");
    errorAttributes[MMEEventKeyAppVersion] = [NSString stringWithFormat:@"%@ %@",
        NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
        NSBundle.mainBundle.infoDictionary[(id)kCFBundleVersionKey]];

    if (NSProcessInfo.processInfo.operatingSystemVersionString) {
        errorAttributes[MMEEventKeyOSVersion] = NSProcessInfo.processInfo.operatingSystemVersionString;
    }

    errorAttributes[MMEEventKeyModel] = MMEEvent.deviceModel;
    errorAttributes[MMEEventKeyOSVersion] = MMEEvent.osVersion;
    errorAttributes[MMEEventKeyDevice] = MMEEvent.deviceModel;

#if TARGET_OS_MACOS
    if (NSRunningApplication.currentApplication.launchDate) {
        errorAttributes[MMEEventKeyAppStartDate] = [MMEDate.iso8601DateFormatter stringFromDate:NSRunningApplication.currentApplication.launchDate];
    }
#endif

    // Check for underlying exception and add the stack trace
    if ([eventsError.userInfo.allKeys containsObject:MMEErrorUnderlyingExceptionKey]) {
        NSException *errorException = eventsError.userInfo[MMEErrorUnderlyingExceptionKey];
        NSMutableString *callStack = NSMutableString.new;
        NSUInteger stackHeight = errorException.callStackSymbols.count;
        NSUInteger index = 0;
        while (index < stackHeight) {
            NSString *stackSymbol = errorException.callStackSymbols[index];
            [callStack appendString:[MMEEvent redactedStackFrame:stackSymbol]];
            if (index < stackHeight) {
                [callStack appendString:@"\n"];
            }
            index++;
        }
        errorAttributes[MMEEventKeyStackTrace] = callStack;

        /* compute a hash of the full trace */
        NSData *callstackDigest = [[errorException.callStackSymbols componentsJoinedByString:@"+"] dataUsingEncoding:NSUTF8StringEncoding];
        if (callstackDigest) {
            uint8_t digest[CC_SHA224_DIGEST_LENGTH];
            CC_SHA224(callstackDigest.bytes, (unsigned)callstackDigest.length, digest);
            NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA224_BLOCK_BYTES];
            for(int i = 0; i < CC_SHA224_DIGEST_LENGTH; i++) {
                [output appendFormat:@"%02x", digest[i]];
            }

            if (output) {
                errorAttributes[MMEEventKeyStackTraceHash] = output;
            }
        }
    }
    else {
        errorAttributes[MMEEventKeyStackTrace] = [NSString stringWithFormat:@"%@/%ld %@ %@",
            eventsError.domain, (long)eventsError.code,
            (eventsError.localizedDescription ?: @"") ,
            (eventsError.localizedFailureReason ?: MMEEventKeyErrorNoReason)];
    }

    return [MMEEvent eventWithAttributes:errorAttributes error:createError];
}

// MARK: - Debug Events

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeLocalDebug;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)debugEventWithError:(NSError*) error {
    NSMutableDictionary* eventAttributes = [NSMutableDictionary dictionaryWithObject:MMEDebugEventTypeError forKey:MMEDebugEventType];
    eventAttributes[MMEEventKeyErrorCode] = @(error.code);
    eventAttributes[MMEEventKeyErrorDomain] = (error.domain ?: MMEEventKeyErrorNoDomain);
    eventAttributes[MMEEventKeyErrorDescription] = (error.localizedDescription ?: error.description);
    eventAttributes[MMEEventKeyErrorFailureReason] = (error.localizedFailureReason ?: MMEEventKeyErrorNoReason);

    return [self debugEventWithAttributes:eventAttributes];
}

+ (instancetype)debugEventWithException:(NSException*) except {
    NSMutableDictionary* eventAttributes = [NSMutableDictionary dictionaryWithObject:MMEDebugEventTypeError forKey:MMEDebugEventType];
    eventAttributes[MMEEventKeyErrorDescription] = except.name;
    eventAttributes[MMEEventKeyErrorFailureReason] = (except.reason ?: MMEEventKeyErrorNoReason);

    return [self debugEventWithAttributes:eventAttributes];
}

// MARK: - Deprecated

+ (instancetype)eventWithDate:(NSDate *)eventDate name:(NSString *)eventName attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyCreated] = [MMEDate.iso8601DateFormatter stringFromDate:eventDate];
    eventAttributes[MMEEventKeyEvent] = eventName;

    return [self eventWithAttributes:eventAttributes];
}

+ (instancetype)eventWithName:(NSString *)eventName attributes:(NSDictionary *)attributes {
    return [self eventWithDate:MMEDate.date name:eventName attributes:attributes];
}

+ (instancetype)telemetryMetricsEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeTelemetryMetrics;
    eventAttributes[MMEEventKeyCreated] = dateString;

    return [self eventWithAttributes:eventAttributes];
}

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(MMECommonEventData *)commonEventData {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeLocation;
    eventAttributes[MMEEventKeySource] = MMEEventSource;
    eventAttributes[MMEEventKeySessionId] = instanceIdentifer;
    eventAttributes[MMEEventKeyOperatingSystem] = MMEEvent.osVersion;
    if (![MMEEvent.applicationState isEqualToString:MMEApplicationStateUnknown]) {
        eventAttributes[MMEEventKeyApplicationState] = MMEEvent.applicationState;
    }

    return [self eventWithAttributes:eventAttributes];
}

+ (instancetype)mapLoadEventWithDateString:(NSString *)dateString commonEventData:(MMECommonEventData *)commonEventData {
    NSMutableDictionary *eventAttributes = NSMutableDictionary.dictionary;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeMapLoad;
    eventAttributes[MMEEventKeyCreated] = dateString;
    eventAttributes[MMEEventKeyVendorID] = MMEEvent.vendorId;
    eventAttributes[MMEEventKeyModel] = MMEEvent.deviceModel;
    eventAttributes[MMEEventKeyOperatingSystem] = MMEEvent.osVersion;
    eventAttributes[MMEEventKeyResolution] = @(MMEEvent.screenScale);
#if TARGET_OS_IOS || TARGET_OS_TVOS
    eventAttributes[MMEEventKeyAccessibilityFontScale] = @(UIApplication.sharedApplication.mme_contentSizeScale);
    eventAttributes[MMEEventKeyOrientation] = UIDevice.currentDevice.mme_deviceOrientation;
#endif
    eventAttributes[MMEEventKeyWifi] = @(MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi);

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)mapTapEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeMapTap;
    eventAttributes[MMEEventKeyCreated] = dateString;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    eventAttributes[MMEEventKeyOrientation] = UIDevice.currentDevice.mme_deviceOrientation;
#endif
    eventAttributes[MMEEventKeyWifi] = @(MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi);

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)mapDragEndEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeMapDragEnd;
    eventAttributes[MMEEventKeyCreated] = dateString;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    eventAttributes[MMEEventKeyOrientation] = UIDevice.currentDevice.mme_deviceOrientation;
#endif
    eventAttributes[MMEEventKeyWifi] = @(MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi);

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)mapOfflineDownloadStartEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEventTypeOfflineDownloadStart;
    eventAttributes[MMEEventKeyCreated] = dateString;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)mapOfflineDownloadEndEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEventTypeOfflineDownloadEnd;
    eventAttributes[MMEEventKeyCreated] = dateString;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)navigationEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    return [MMEEvent eventWithName:name attributes:attributes];
}

+ (instancetype)visionEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    return [MMEEvent eventWithName:name attributes:attributes];
}

+ (instancetype)searchEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    return [MMEEvent eventWithName:name attributes:attributes];
}

+ (instancetype)carplayEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    return [MMEEvent eventWithName:name attributes:attributes];
}

+ (instancetype)eventWithDateString:(NSString *)dateString name:(NSString *)name attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = name;
    eventAttributes[MMEEventKeyCreated] = dateString;

    return [self eventWithAttributes:eventAttributes];
}

+ (instancetype)crashEventReporting:(NSError *)eventsError error:(NSError **)createError {
    return [self errorEventReporting:eventsError error:createError];
}

// MARK: - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

// MARK: - Designated Initializer


- (instancetype)init {
    return [self initWithAttributes:MMEEvent.nilAttributes error:nil];
}

- (instancetype)initWithAttributes:(NSDictionary *)eventAttributes error:(NSError **)error {
    @try {
        if (eventAttributes == MMEEvent.nilAttributes) { // special case for initFromCoder
            self = [super init];
        }
        else if ([NSJSONSerialization isValidJSONObject:eventAttributes]) {
            if (![eventAttributes.allKeys containsObject:MMEEventKeyEvent]) { // is required
                *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventInitMissingKey userInfo:@{
                    NSLocalizedDescriptionKey: @"eventAttributes does not contain MMEEventKeyEvent",
                    MMEErrorEventAttributesKey: eventAttributes ?: NSNull.null
                }];
                self = nil;
            }
            else if (self = [super init]) {
                    _dateStorage = MMEDate.date;
                    NSMutableDictionary* eventAttributesStorage = [eventAttributes mutableCopy];

                    if (![eventAttributesStorage.allKeys containsObject:MMEEventKeyCreated]) {
                        eventAttributesStorage[MMEEventKeyCreated] = [MMEDate.iso8601DateFormatter stringFromDate:_dateStorage];
                    }

                    self.attributesStorage = eventAttributesStorage;
            }
        }
        else {
            *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventInitInvalid userInfo:@{
                NSLocalizedDescriptionKey: @"eventAttributes is not a valid JSON Object",
                MMEErrorEventAttributesKey: eventAttributes ?: NSNull.null
            }];
            self = nil;
        }
    }
    @catch(NSException* eventAttributesException) {
        *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventInitException userInfo:@{
            NSLocalizedDescriptionKey: @"exception processing eventAttributes",
            MMEErrorUnderlyingExceptionKey: eventAttributesException,
            MMEErrorEventAttributesKey: eventAttributes ?: NSNull.null
        }];
        self = nil;
    }

    return self;
}

// MARK: - Properties

- (NSDate *)date {
    return [_dateStorage copy];
}

- (NSString *)name {
    return ([_attributesStorage.allKeys containsObject:MMEEventKeyEvent] ? [_attributesStorage[MMEEventKeyEvent] copy] : nil);
}

- (NSDictionary *)attributes {
    return (_attributesStorage ? [NSDictionary dictionaryWithDictionary:_attributesStorage] : nil);
}

// MARK: - MMEEvent

- (BOOL)isEqualToEvent:(MMEEvent *)event {
    if (!event) {
        return NO;
    }
    
    BOOL hasEqualDate = [self.dateStorage isEqualToDate:event.dateStorage];
    BOOL hasEqualAttributes = [self.attributesStorage isEqual:event.attributesStorage];
    
    return (hasEqualDate && hasEqualAttributes);
}

// MARK: - NSObject overrides

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (other && ![other isKindOfClass:MMEEvent.class]) {
        return  NO;
    }
    
    return [self isEqualToEvent:other];
}

- (NSUInteger)hash {
    return (self.name.hash ^ self.attributes.hash);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, date=%@, attributes=%@>",
        NSStringFromClass(self.class), self.name, self.date, self.attributes];
}

// MARK: - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    MMEEvent *copy = [MMEEvent new];
    copy.dateStorage = self.dateStorage.copy;
    copy.attributesStorage = self.attributesStorage.copy;
    return copy;
}

// MARK: - NSCoding

static NSInteger const MMEEventVersion1 = 1; // Name, Date & Attributes Dictionary
static NSInteger const MMEEventVersion2 = 2; // Date & Attributes Dictionary
static NSString * const MMEEventVersionKey = @"MMEEventVersion";
static NSString * const MMEEventNameKey = @"MMEEventName";
static NSString * const MMEEventDateKey = @"MMEEventDate";
static NSString * const MMEEventAttributesKey = @"MMEEventAttributes";

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        NSInteger encodedVersion = [aDecoder decodeIntegerForKey:MMEEventVersionKey];
        
        if (encodedVersion > MMEEventVersion2) {
            NSString *errorString = [[NSString alloc] initWithFormat:@"%@ %@ encodedVersion %li > MMEEventVersion %li",
                                     self.name ?: @"nil", NSStringFromClass(self.class), (long)encodedVersion, (long)MMEEventVersion1];
            NSError *encodingError = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventEncoding userInfo:@{MMEErrorDescriptionKey: errorString}];
            [MMEEventsManager.sharedManager reportError:encodingError];
            return nil;
        }
        
        _attributesStorage = [aDecoder decodeObjectOfClass:NSDictionary.class forKey:MMEEventAttributesKey];
        _dateStorage = [aDecoder decodeObjectOfClass:MMEDate.class forKey:MMEEventDateKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_dateStorage forKey:MMEEventDateKey];
    [aCoder encodeObject:_attributesStorage forKey:MMEEventAttributesKey];
    [aCoder encodeInteger:MMEEventVersion2 forKey:MMEEventVersionKey];
}

@end

// MARK: - Deprecated Class

@implementation MMECommonEventData
@end
