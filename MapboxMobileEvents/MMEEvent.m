#import "MMEEvent.h"
#import "MMEConstants.h"
#import "MMECommonEventData.h"
#import "MMEReachability.h"

@implementation MMEEvent

+ (instancetype)turnstileEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *turnstileEvent = [[MMEEvent alloc] init];
    turnstileEvent.name = MMEEventTypeAppUserTurnstile;
    turnstileEvent.attributes = attributes;
    return turnstileEvent;
}

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(MMECommonEventData *)commonEventData {

    MMEEvent *locationEvent = [[MMEEvent alloc] init];
    locationEvent.name = MMEEventTypeLocation;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = locationEvent.name;
    commonAttributes[MMEEventKeySource] = MMEEventSource;
    commonAttributes[MMEEventKeySessionId] = instanceIdentifer;
    commonAttributes[MMEEventKeyOperatingSystem] = commonEventData.iOSVersion;
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

+ (instancetype)mapLoadEventWithDateString:(NSString *)dateString commonEventData:(MMECommonEventData *)commonEventData; {
    MMEEvent *mapLoadEvent = [[MMEEvent alloc] init];
    mapLoadEvent.name = MMEEventTypeMapLoad;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[MMEEventKeyEvent] = mapLoadEvent.name;
    attributes[MMEEventKeyCreated] = dateString;
    attributes[MMEEventKeyVendorID] = commonEventData.vendorId;
    attributes[MMEEventKeyModel] = commonEventData.model;
    attributes[MMEEventKeyOperatingSystem] = commonEventData.iOSVersion;
    attributes[MMEEventKeyResolution] = @(commonEventData.scale);
    attributes[MMEEventKeyAccessibilityFontScale] = @([self contentSizeScale]);
    attributes[MMEEventKeyOrientation] = [self deviceOrientation];
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
    commonAttributes[MMEEventKeyOrientation] = [self deviceOrientation];
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
    commonAttributes[MMEEventKeyOrientation] = [self deviceOrientation];
    commonAttributes[MMEEventKeyWifi] = @([[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi]);
    [commonAttributes addEntriesFromDictionary:attributes];
    mapTapEvent.attributes = commonAttributes;
    return mapTapEvent;
}

+ (instancetype)navigationEventWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    MMEEvent *navigationEvent = [[MMEEvent alloc] init];
    navigationEvent.name = name;
    navigationEvent.attributes = attributes;
    return navigationEvent;
}

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *debugEvent = [[MMEEvent alloc] init];
    debugEvent.name = MMEEventTypeLocalDebug;
    debugEvent.attributes = [attributes copy];
    return debugEvent;
}

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

- (BOOL)isEqualToEvent:(MMEEvent *)event {
    if (!event) {
        return NO;
    }
    
    BOOL hasEqualName = [self.name isEqualToString:event.name];
    BOOL hasEqualAttributes = [self.attributes isEqual:event.attributes];
    
    return hasEqualName && hasEqualAttributes;
}

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
    return self.name.hash ^ self.attributes.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, attributes=%@>", NSStringFromClass([self class]), self.name, self.attributes];
}

@end
