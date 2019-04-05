#import "MMEEvent.h"
#import "MMEDate.h"
#import "MMEConstants.h"
#import "MMECommonEventData.h"
#import "MMEReachability.h"
#import "MMEEventsManager.h"

#if TARGET_OS_IOS || TARGET_OS_TVOS
#import "UIKit+MMEMobileEvents.h"
#endif

@interface MMEEvent ()
@property(nonatomic,retain) MMEDate *dateStorage;
@property(nonatomic,retain) NSDictionary *attributesStorage;

@end

#pragma mark -

@implementation MMEEvent

+ (NSDictionary *)nilAttributes {
    static NSDictionary *nilAttributes = nil;
    if (!nilAttributes) {
        nilAttributes = @{};
    }
    return nilAttributes;
}

#pragma mark - Generic Events

+ (instancetype)eventWithAttributes:(NSDictionary *)attributes {
    NSError *eventError = nil;
    MMEEvent *newEvent = [MMEEvent eventWithAttributes:attributes error:&eventError];
    if (eventError != nil) {
        [MMEEventsManager.sharedManager reportError:eventError];
    }

    return newEvent;
}

+ (instancetype)eventWithAttributes:(NSDictionary *)attributes error:(NSError **)error {
    return [MMEEvent.alloc initWithAttributes:attributes error:error];
}

#pragma mark - Custom Events

+ (instancetype)turnstileEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeAppUserTurnstile;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)visitEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeVisit;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

#pragma mark - Crash Events

+ (instancetype)crashEventReporting:(NSError *)eventsError error:(NSError **)createError {
    // start with common event data
    NSMutableDictionary *crashAttributes = MMECommonEventData.commonEventData;
    crashAttributes[MMEEventKeyEvent] = MMEEventMobileCrash;
    crashAttributes[MMEEventKeyBuildType] = (DEBUG ? @"debug" : @"release");
    crashAttributes[MMEEventKeyIsSilentCrash] = @"yes";
    crashAttributes[MMEEventSDKIdentifier] = [NSString stringWithFormat:@"%@-%@",
        MMEEventsManager.sharedManager.userAgentBase,
        MMEEventsManager.sharedManager.hostSDKVersion];
    crashAttributes[MMEEventKeyStackTraceHash] = [NSString stringWithFormat:@"%@/%ld %@ %@", eventsError.domain, (long)eventsError.code,
        (eventsError.localizedDescription ?: @"") ,
        (eventsError.localizedFailureReason ?: MMEEventKeyErrorNoReason)];
    crashAttributes[MMEEventKeyAppID] = (NSBundle.mainBundle.bundleIdentifier ?: @"unknown");
    crashAttributes[MMEEventKeyAppVersion] = [NSString stringWithFormat:@"%@ %@",
        NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
        NSBundle.mainBundle.infoDictionary[(id)kCFBundleVersionKey]];

    if (NSProcessInfo.processInfo.operatingSystemVersionString) {
        crashAttributes[MMEEventKeyOSVersion] = NSProcessInfo.processInfo.operatingSystemVersionString;
    }

#if TARGET_OS_MACOS
    if (NSRunningApplication.currentApplicaiton.launchDate) {
        crashAttributes[MMEEventKeyAppStartDate] = [MMEDate.iso8601DateFormatter stringFromDate:NSRunningApplication.currentApplicaiton.launchDate];
    }
#endif

    // Check for underlying exception and add the stack trace
    if ([eventsError.userInfo.allKeys containsObject:MMEErrorUnderlyingExceptionKey]) {
        NSException *errorException = eventsError.userInfo[MMEErrorUnderlyingExceptionKey];
        NSMutableString *callStack = NSMutableString.new;
        NSUInteger stackHeight = errorException.callStackSymbols.count;
        NSUInteger index = 0;
        while (index < stackHeight) {
            NSString *stackFrame = [NSString stringWithFormat:@"%@ %@",
                errorException.callStackReturnAddresses[index], errorException.callStackSymbols[index]];
            if (index > 0) {
                [callStack appendString:@"\n"];
            }
            [callStack appendString:stackFrame];
            index++;
        }
        crashAttributes[MMEEventKeyStackTrace] = callStack;
    }

    return [MMEEvent eventWithAttributes:crashAttributes error:createError];
}

#pragma mark - Debug Events

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeLocalDebug;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)debugEventWithError:(NSError*) error {
    NSMutableDictionary* eventAttributes = [NSMutableDictionary dictionaryWithObject:MMEDebugEventTypeError forKey:MMEDebugEventType];
    eventAttributes[MMEEventKeyErrorCode] = @(error.code);
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

#pragma mark - Deperecated

+ (instancetype)eventWithDate:(NSDate *)eventDate name:(NSString *)eventName attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyCreated] = [MMEDate.iso8601DateFormatter stringFromDate:eventDate];
    eventAttributes[MMEEventKeyEvent] = eventName;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)eventWithName:(NSString *)eventName attributes:(NSDictionary *)attributes {
    return [MMEEvent eventWithDate:MMEDate.date name:eventName attributes:attributes];
}

+ (instancetype)telemetryMetricsEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeTelemetryMetrics;
    eventAttributes[MMEEventKeyCreated] = dateString;

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(MMECommonEventData *)commonEventData {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeLocation;
    eventAttributes[MMEEventKeySource] = MMEEventSource;
    eventAttributes[MMEEventKeySessionId] = instanceIdentifer;
    eventAttributes[MMEEventKeyOperatingSystem] = commonEventData.osVersion;
    if (![MMECommonEventData.applicationState isEqualToString:MMEApplicationStateUnknown]) {
        eventAttributes[MMEEventKeyApplicationState] = MMECommonEventData.applicationState;
    }

    return [MMEEvent eventWithAttributes:eventAttributes];
}

+ (instancetype)mapLoadEventWithDateString:(NSString *)dateString commonEventData:(MMECommonEventData *)commonEventData {
    NSMutableDictionary *eventAttributes = NSMutableDictionary.dictionary;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeMapLoad;
    eventAttributes[MMEEventKeyCreated] = dateString;
    eventAttributes[MMEEventKeyVendorID] = commonEventData.vendorId;
    eventAttributes[MMEEventKeyModel] = commonEventData.model;
    eventAttributes[MMEEventKeyOperatingSystem] = commonEventData.osVersion;
    eventAttributes[MMEEventKeyResolution] = @(commonEventData.scale);
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

    return [MMEEvent eventWithAttributes:eventAttributes];
}

#pragma mark - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

#pragma mark - Designated Initilizer


- (instancetype)init {
    return [self initWithAttributes:MMEEvent.nilAttributes error:nil];
}

- (instancetype)initWithAttributes:(NSDictionary *)eventAttributes error:(NSError **)error {
    if (eventAttributes == MMEEvent.nilAttributes) { // special case for initFromCoder
        self = [super init];
    }
    else if ([NSJSONSerialization isValidJSONObject:eventAttributes]) {
        if (![eventAttributes.allKeys containsObject:MMEEventKeyEvent]) { // is required
            *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventInit userInfo:@{
                MMEErrorDescriptionKey: @"eventAttributes does not contain MMEEventKeyEvent",
                MMEErrorEventAttributesKey: eventAttributes
            }];
            self = nil;
        }
        else if (self = [super init]) {
            @try {
                _dateStorage = MMEDate.date;
                NSMutableDictionary* eventAttributesStorage = [eventAttributes mutableCopy];

                if (![eventAttributesStorage.allKeys containsObject:MMEEventKeyCreated]) {
                    eventAttributesStorage[MMEEventKeyCreated] = [MMEDate.iso8601DateFormatter stringFromDate:_dateStorage];
                }

                self.attributesStorage = eventAttributesStorage;
            }
            @catch(NSException* eventAttributesException) {
                *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventInit userInfo:@{
                    MMEErrorDescriptionKey: @"exception processing eventAttributes",
                    MMEErrorUnderlyingExceptionKey: eventAttributesException,
                    MMEErrorEventAttributesKey: eventAttributes
                }];
                self = nil;
            }
        }
    }
    else {
        *error = [NSError errorWithDomain:MMEErrorDomain code:MMEErrorEventInit userInfo:@{
            MMEErrorDescriptionKey: @"eventAttributes is not a valid JSON Object",
            MMEErrorEventAttributesKey: eventAttributes
        }];
        self = nil;
    }

    return self;
}

#pragma mark - Properties

- (NSDate *)date {
    return [_dateStorage copy];
}

- (NSString *)name {
    return ([_attributesStorage.allKeys containsObject:MMEEventKeyEvent] ? [_attributesStorage[MMEEventKeyEvent] copy] : nil);
}

- (NSDictionary *)attributes {
    return (_attributesStorage ? [NSDictionary dictionaryWithDictionary:_attributesStorage] : nil);
}

#pragma mark - MMEEvent

- (BOOL)isEqualToEvent:(MMEEvent *)event {
    if (!event) {
        return NO;
    }
    
    BOOL hasEqualDate = [self.dateStorage isEqualToDate:event.dateStorage];
    BOOL hasEqualAttributes = [self.attributesStorage isEqual:event.attributesStorage];
    
    return (hasEqualDate && hasEqualAttributes);
}

#pragma mark - NSObject overrides

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

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    MMEEvent *copy = [MMEEvent new];
    copy.dateStorage = self.dateStorage.copy;
    copy.attributesStorage = self.attributesStorage.copy;
    return copy;
}

#pragma mark - NSCoding

static NSInteger const MMEEventVersion1 = 1; // Name, Date & Attributes Dictionary
static NSInteger const MMEEventVersion2 = 2; // Date & Attributes Dictionary
static NSString * const MMEEventVersionKey = @"MMEEventVersion";
static NSString * const MMEEventNameKey = @"MMEEventName";
static NSString * const MMEEventDateKey = @"MMEEventDate";
static NSString * const MMEEventAttributesKey = @"MMEEventAttributes";

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        NSInteger encodedVersion = [aDecoder decodeIntegerForKey:MMEEventVersionKey];
        _dateStorage = [aDecoder decodeObjectOfClass:MMEDate.class forKey:MMEEventDateKey];
        _attributesStorage = [aDecoder decodeObjectOfClass:NSDictionary.class forKey:MMEEventAttributesKey];
        if (encodedVersion > MMEEventVersion2) {
            NSLog(@"%@ WARNING encodedVersion %li > MMEEventVersion %li",
                NSStringFromClass(self.class), (long)encodedVersion, (long)MMEEventVersion1);
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_dateStorage forKey:MMEEventDateKey];
    [aCoder encodeObject:_attributesStorage forKey:MMEEventAttributesKey];
    [aCoder encodeInteger:MMEEventVersion2 forKey:MMEEventVersionKey];
}

@end
