#import "MMEEvent.h"
#import "MMEDate.h"
#import "MMEConstants.h"
#import "MMECommonEventData.h"
#import "MMEReachability.h"

#if TARGET_OS_IOS || TARGET_OS_TVOS
#import <UIKit/UIKit.h>
#endif

@implementation MMEEvent

+ (instancetype)turnstileEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *turnstileEvent = [[MMEEvent alloc] init];
    turnstileEvent.name = MMEEventTypeAppUserTurnstile;
    turnstileEvent.attributes = attributes;
    return turnstileEvent;
}

+ (instancetype)telemetryMetricsEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    MMEEvent *telemetryMetrics = [[MMEEvent alloc] init];
    telemetryMetrics.name = MMEEventTypeTelemetryMetrics;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = telemetryMetrics.name;
    commonAttributes[MMEEventKeyCreated] = dateString;
    [commonAttributes addEntriesFromDictionary:attributes];
    telemetryMetrics.attributes = commonAttributes;
    return telemetryMetrics;
}

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(MMECommonEventData *)commonEventData {

    MMEEvent *locationEvent = [[MMEEvent alloc] init];
    locationEvent.name = MMEEventTypeLocation;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = locationEvent.name;
    commonAttributes[MMEEventKeySource] = MMEEventSource;
    commonAttributes[MMEEventKeySessionId] = instanceIdentifer;
    commonAttributes[MMEEventKeyOperatingSystem] = commonEventData.osVersion;
    NSString *applicationState = [commonEventData applicationState];
    if (![applicationState isEqualToString:MMEApplicationStateUnknown]) {
        commonAttributes[MMEEventKeyApplicationState] = applicationState;
    }
    [commonAttributes addEntriesFromDictionary:attributes];
    locationEvent.attributes = commonAttributes;
    return locationEvent;
}

+ (instancetype)visitEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *visitEvent = [[MMEEvent alloc] init];
    visitEvent.name = MMEEventTypeVisit;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = visitEvent.name;
    [commonAttributes addEntriesFromDictionary:attributes];
    visitEvent.attributes = commonAttributes;
    return visitEvent;
}

+ (instancetype)mapLoadEventWithDateString:(NSString *)dateString commonEventData:(MMECommonEventData *)commonEventData {
    MMEEvent *mapLoadEvent = [[MMEEvent alloc] init];
    mapLoadEvent.name = MMEEventTypeMapLoad;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[MMEEventKeyEvent] = mapLoadEvent.name;
    attributes[MMEEventKeyCreated] = dateString;
    attributes[MMEEventKeyVendorID] = commonEventData.vendorId;
    attributes[MMEEventKeyModel] = commonEventData.model;
    attributes[MMEEventKeyOperatingSystem] = commonEventData.osVersion;
    attributes[MMEEventKeyResolution] = @(commonEventData.scale);
#if TARGET_OS_IOS || TARGET_OS_TVOS
    attributes[MMEEventKeyAccessibilityFontScale] = @([self contentSizeScale]);
    attributes[MMEEventKeyOrientation] = [self deviceOrientation];
#endif
    attributes[MMEEventKeyWifi] = @([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]);
    mapLoadEvent.attributes = attributes;
    return mapLoadEvent;
}

+ (instancetype)mapTapEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    MMEEvent *mapTapEvent = [[MMEEvent alloc] init];
    mapTapEvent.name = MMEEventTypeMapTap;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = mapTapEvent.name;
    commonAttributes[MMEEventKeyCreated] = dateString;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    commonAttributes[MMEEventKeyOrientation] = [self deviceOrientation];
#endif
    commonAttributes[MMEEventKeyWifi] = @([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]);
    [commonAttributes addEntriesFromDictionary:attributes];
    mapTapEvent.attributes = commonAttributes;
    return mapTapEvent;
}

+ (instancetype)mapDragEndEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    MMEEvent *mapTapEvent = [[MMEEvent alloc] init];
    mapTapEvent.name = MMEEventTypeMapDragEnd;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = mapTapEvent.name;
    commonAttributes[MMEEventKeyCreated] = dateString;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    commonAttributes[MMEEventKeyOrientation] = [self deviceOrientation];
#endif
    commonAttributes[MMEEventKeyWifi] = @([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]);
    [commonAttributes addEntriesFromDictionary:attributes];
    mapTapEvent.attributes = commonAttributes;
    return mapTapEvent;
}

+ (instancetype)mapOfflineDownloadStartEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    MMEEvent *mapOfflineDownloadEvent = [[MMEEvent alloc] init];
    mapOfflineDownloadEvent.name = MMEventTypeOfflineDownloadStart;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = mapOfflineDownloadEvent.name;
    commonAttributes[MMEEventKeyCreated] = dateString;
    [commonAttributes addEntriesFromDictionary:attributes];
    mapOfflineDownloadEvent.attributes = commonAttributes;
    return mapOfflineDownloadEvent;
}

+ (instancetype)mapOfflineDownloadEndEventWithDateString:(NSString *)dateString attributes:(NSDictionary *)attributes {
    MMEEvent *mapOfflineDownloadEvent = [[MMEEvent alloc] init];
    mapOfflineDownloadEvent.name = MMEventTypeOfflineDownloadEnd;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = mapOfflineDownloadEvent.name;
    commonAttributes[MMEEventKeyCreated] = dateString;
    [commonAttributes addEntriesFromDictionary:attributes];
    mapOfflineDownloadEvent.attributes = commonAttributes;
    return mapOfflineDownloadEvent;
}

+ (instancetype)navigationEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *navigationEvent = [[MMEEvent alloc] init];
    navigationEvent.name = name;
    navigationEvent.attributes = attributes;
    return navigationEvent;
}

+ (instancetype)visionEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *visionEvent = [[MMEEvent alloc] init];
    visionEvent.name = name;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = visionEvent.name;
    [commonAttributes addEntriesFromDictionary:attributes];
    visionEvent.attributes = commonAttributes;
    return visionEvent;
}

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *debugEvent = [[MMEEvent alloc] init];
    debugEvent.name = MMEEventTypeLocalDebug;
    debugEvent.attributes = [attributes copy];
    return debugEvent;
}

+ (instancetype)debugEventWithError:(NSError*) error {
    return [self debugEventWithAttributes:@{
        MMEDebugEventType: MMEDebugEventTypeError,
        MMEEventKeyErrorCode: @(error.code),
        MMEEventKeyErrorDescription: error.localizedDescription,
        MMEEventKeyErrorFailureReason: error.localizedFailureReason
    }];
}

+ (instancetype)debugEventWithException:(NSException*) except {
    return [self debugEventWithAttributes:@{
        MMEDebugEventType: MMEDebugEventTypeError,
        MMEEventKeyErrorDescription: except.name,
        MMEEventKeyErrorFailureReason: except.reason
        // TODO add the stack trace via .callstackSymbols after sanatizing the list
    }];
}

+ (instancetype)searchEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *searchEvent = [[MMEEvent alloc] init];
    searchEvent.name = name;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = searchEvent.name;
    [commonAttributes addEntriesFromDictionary:attributes];
    searchEvent.attributes = commonAttributes;
    return searchEvent;
}

+ (instancetype)carplayEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *carplayEvent = [[MMEEvent alloc] init];
    carplayEvent.name = name;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = carplayEvent.name;
    [commonAttributes addEntriesFromDictionary:attributes];
    carplayEvent.attributes = commonAttributes;
    return carplayEvent;
}

+ (instancetype)eventWithDateString:(NSString *)dateString name:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *event = [[MMEEvent alloc] init];
    event.name = name;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = event.name;
    commonAttributes[MMEEventKeyCreated] = dateString;
    [commonAttributes addEntriesFromDictionary:attributes];
    event.attributes = commonAttributes;
    return event;
}

#pragma mark -

#if TARGET_OS_IOS || TARGET_OS_TVOS
+ (NSInteger)contentSizeScale {
    NSInteger result = -9999;
    
    NSString *sc = [UIApplication sharedApplication].preferredContentSizeCategory;
    
    if ([sc isEqualToString:UIContentSizeCategoryExtraSmall]) {
        result = -3;
    } else if ([sc isEqualToString:UIContentSizeCategorySmall]) {
        result = -2;
    } else if ([sc isEqualToString:UIContentSizeCategoryMedium]) {
        result = -1;
    } else if ([sc isEqualToString:UIContentSizeCategoryLarge]) {
        result = 0;
    } else if ([sc isEqualToString:UIContentSizeCategoryExtraLarge]) {
        result = 1;
    } else if ([sc isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
        result = 2;
    } else if ([sc isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
        result = 3;
    } else if ([sc isEqualToString:UIContentSizeCategoryAccessibilityMedium]) {
        result = -11;
    } else if ([sc isEqualToString:UIContentSizeCategoryAccessibilityLarge]) {
        result = 10;
    } else if ([sc isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge]) {
        result = 11;
    } else if ([sc isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
        result = 12;
    } else if ([sc isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
        result = 13;
    }
    
    return result;
}

+ (NSString *)deviceOrientation {
    NSString *result;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationUnknown:
            result = @"Unknown";
            break;
        case UIDeviceOrientationPortrait:
            result = @"Portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            result = @"PortraitUpsideDown";
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = @"LandscapeLeft";
            break;
        case UIDeviceOrientationLandscapeRight:
            result = @"LandscapeRight";
            break;
        case UIDeviceOrientationFaceUp:
            result = @"FaceUp";
            break;
        case UIDeviceOrientationFaceDown:
            result = @"FaceDown";
            break;
        default:
            result = @"Default - Unknown";
            break;
    }
    return result;
}
#endif

#pragma mark - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

#pragma mark -

- (BOOL)isEqualToEvent:(MMEEvent *)event {
    if (!event) {
        return NO;
    }
    
    BOOL hasEqualName = [self.name isEqualToString:event.name];
    BOOL hasEqualDate = (self.date.timeIntervalSinceReferenceDate == event.date.timeIntervalSinceReferenceDate);
    BOOL hasEqualAttributes = [self.attributes isEqual:event.attributes];
    
    return (hasEqualName && hasEqualDate && hasEqualAttributes);
}

#pragma mark - NSObject overrides

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (![other isKindOfClass:[MMEEvent class]]) {
        return  NO;
    }
    
    return [self isEqualToEvent:other];
}

- (NSUInteger)hash {
    return (self.name.hash ^ self.attributes.hash);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, date=%@, attributes=%@>", NSStringFromClass(self.class), self.name, self.date, self.attributes];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    MMEEvent *copy = [MMEEvent new];
    copy.name = [self.name copy];
    copy.date = [self.date copy];
    copy.attributes = [self.attributes copy];
    return copy;
}

#pragma mark - NSCoding

static NSInteger const MMEEventVersion1 = 1;
static NSString * const MMEEventVersionKey = @"MMEEventVersion";
static NSString * const MMEEventNameKey = @"MMEEventName";
static NSString * const MMEEventDateKey = @"MMEEventDate";
static NSString * const MMEEventAttributesKey = @"MMEEventAttributes";


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSInteger encodedVersion = [aDecoder decodeIntegerForKey:MMEEventVersionKey];
        _name = [aDecoder decodeObjectOfClass:NSString.class forKey:MMEEventNameKey];
        _date = [aDecoder decodeObjectOfClass:MMEDate.class forKey:MMEEventDateKey];
        _attributes = [aDecoder decodeObjectOfClass:NSDictionary.class forKey:MMEEventAttributesKey];
        if (encodedVersion > MMEEventVersion1) {
            NSLog(@"%@ WARNING encodedVersion %li > MMEEventVersion %li", NSStringFromClass(self.class), encodedVersion, MMEEventVersion1);
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_name forKey:MMEEventNameKey];
    [aCoder encodeObject:_date forKey:MMEEventDateKey];
    [aCoder encodeObject:_attributes forKey:MMEEventAttributesKey];
    [aCoder encodeInteger:MMEEventVersion1 forKey:MMEEventVersionKey];
}

@end
