#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>
#import "MMEEvent.h"
#import "MMEConfigurationProviding.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEventsManager.h"
#import "MMEReachability.h"
#import "MMEConfigation.h"
#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"
#import "MMELogger.h"

#import "NSProcessInfo+SystemInfo.h"

#if TARGET_OS_IOS || TARGET_OS_TVOS
#import "UIKit+MMEMobileEvents.h"
#import "NSBundle+MMEMobileEvents.h"
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

    // TODO: This side effects makes it difficult to test? Perhaps there's another approach for reporting?
    if (eventError != nil) {
        [MMEEventsManager.sharedManager reportError:eventError];
    }

    return newEvent;
}

+ (instancetype)eventWithAttributes:(NSDictionary *)attributes error:(NSError **)error {
    return [self.alloc initWithAttributes:attributes error:error];
}

// MARK: - Custom Events

/*! TurnstileEvent Convenience Initializer */
+ (nullable instancetype)turnstileEventWithConfiguration:(id <MMEConfigurationProviding>)config
                                                   skuID:(nullable NSString*)skuID
                                                   error:(NSError**)error {

    if (!config.accessToken) {
        MMELog(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No access token sent - can not send turntile event, instance: %@",
                                                               skuID ?: @"nil"]));

        NSError *missingRequirementError = [NSError errorWithDomain:MMEErrorDomain
                                                          code:MMEErrorEventInitInvalid
                                                      userInfo:@{
                                                          NSLocalizedDescriptionKey: @"Turnstile event unable to initialize due to missing accessToken"

                                                      }
                                       ];
        *error = missingRequirementError;
        return nil;
    }

    if (!NSProcessInfo.mme_vendorId) {
        MMELog(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No vendor id available - can not send turntile event, instance: %@",
                                                               skuID ?: @"nil"]));

        NSError *missingRequirementError = [NSError errorWithDomain:MMEErrorDomain
                                                               code:MMEErrorEventInitInvalid
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: @"Turnstile event unable to initialize due to missing accessToken"

                                                           }
                                            ];
        *error = missingRequirementError;
        return nil;
    }

    if (!NSProcessInfo.mme_deviceModel) {
        MMELog(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No model available - can not send turntile event, instance: %@",
                                                               skuID ?: @"nil"]));

        NSError *missingRequirementError = [NSError errorWithDomain:MMEErrorDomain
                                                               code:MMEErrorEventInitInvalid
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: @"Turnstile event unable to initialize due to missing device model"

                                                           }
                                            ];
        *error = missingRequirementError;

        return nil;
    }

    if (!NSProcessInfo.mme_osVersion) {
        MMELog(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No iOS version available - can not send turntile event, instance: %@",
                                                               skuID ?: @"nil"]));

        NSError *missingRequirementError = [NSError errorWithDomain:MMEErrorDomain
                                                               code:MMEErrorEventInitInvalid
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: @"Turnstile event unable to initialize due to missing OS Version"

                                                           }
                                            ];
        *error = missingRequirementError;

        return nil;
    }

    // TODO: remove this check when we switch to reformed UA strings for the events api
    if (!config.legacyUserAgentBase) {
        MMELog(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No user agent base set - can not send turntile event, instance: %@",
                                                               skuID ?: @"nil"]));

        NSError *missingRequirementError = [NSError errorWithDomain:MMEErrorDomain
                                                               code:MMEErrorEventInitInvalid
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: @"Turnstile event unable to initialize due to missing user agent base"

                                                           }
                                            ];
        *error = missingRequirementError;

        return nil;
    }

    // TODO: remove this check when we switch to reformed UA strings for the events api
    if (!config.legacyHostSDKVersion) {
        MMELog(MMELogInfo, MMEDebugEventTypeTurnstileFailed, ([NSString stringWithFormat:@"No host SDK version set - can not send turntile event, instance: %@",
                                                               skuID ?: @"nil"]));

        NSError *missingRequirementError = [NSError errorWithDomain:MMEErrorDomain
                                                               code:MMEErrorEventInitInvalid
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: @"Turnstile event unable to initialize due to missing host SDK version"

                                                           }
                                            ];
        *error = missingRequirementError;

        return nil;
    }


    return [self turnstileEventWithCreatedDate:[NSDate date]
                                      vendorID:NSProcessInfo.mme_vendorId
                                   deviceModel:NSProcessInfo.mme_deviceModel
                               operatingSystem:NSProcessInfo.mme_osVersion
                                 sdkIdentifier:config.legacyUserAgentBase
                                    sdkVersion:config.legacyHostSDKVersion
                            isTelemetryEnabled:config.isCollectionEnabled
                       locationServicesEnabled:CLLocationManager.locationServicesEnabled
                         locationAuthorization:CLLocationManager.mme_authorizationStatusString
                                         skuID:skuID];
}

+(instancetype)turnstileEventWithCreatedDate:(NSDate*)createdDate
                                    vendorID:(NSString*)vendorID
                                 deviceModel:(NSString*)deviceModel
                             operatingSystem:(NSString*)operatingSystem
                               sdkIdentifier:(NSString*)sdkIdentifier
                                  sdkVersion:(NSString*)sdkVersion
                          isTelemetryEnabled:(BOOL)isTelemetryEnabled
                     locationServicesEnabled:(BOOL)locationServicesEnabled
                       locationAuthorization:(NSString*)locationAuthorization
                                       skuID:(nullable NSString*)skuID {

    NSDictionary *attributes = @{
        MMEEventKeyEvent: MMEEventTypeAppUserTurnstile,
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:createdDate],
        MMEEventKeyVendorId: vendorID,

        // MMEEventKeyDevice is synonomous with MMEEventKeyModel but the server will only accept "device" in turnstile events
        MMEEventKeyDevice: deviceModel,
        MMEEventKeyOperatingSystem: operatingSystem,
        MMEEventSDKIdentifier: sdkIdentifier,
        MMEEventSDKVersion: sdkVersion,
        MMEEventKeyEnabledTelemetry: @(isTelemetryEnabled),
        MMEEventKeyLocationEnabled: @(locationServicesEnabled),
        MMEEventKeyLocationAuthorization: locationAuthorization,
        MMEEventKeySkuId: skuID ?: NSNull.null
    };
    return [self eventWithAttributes: attributes];
}


+ (instancetype)visitEventWithVisit:(CLVisit*)visit {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:visit.coordinate.latitude
                                                      longitude:visit.coordinate.longitude];

    NSMutableDictionary *attributes =  [@{
        MMEEventKeyEvent: MMEEventTypeVisit,
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
        MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
        MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
        MMEEventHorizontalAccuracy: @(visit.horizontalAccuracy),
        MMEEventKeyVerticalAccuracy: @([location mme_roundedVerticalAccuracy]),
        MMEEventKeyArrivalDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.arrivalDate],
        MMEEventKeyDepartureDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.departureDate]
    } mutableCopy];

    if ([location floor]) {
        [attributes setValue:@([location floor].level) forKey:MMEEventKeyFloor];
    }

    return [self eventWithAttributes:attributes];
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

    // TODO: Enable this to come from extra parameter or included a supplemental content injected just before sending?
    errorAttributes[MMEEventSDKIdentifier] = MMEEventsManager.sharedManager.configuration.userAgentString;
    errorAttributes[MMEEventKeyAppID] = (NSBundle.mainBundle.bundleIdentifier ?: @"unknown");
    errorAttributes[MMEEventKeyAppVersion] = [NSString stringWithFormat:@"%@ %@",
        NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
        NSBundle.mainBundle.infoDictionary[(id)kCFBundleVersionKey]];

    if (NSProcessInfo.processInfo.operatingSystemVersionString) {
        errorAttributes[MMEEventKeyOSVersion] = NSProcessInfo.processInfo.operatingSystemVersionString;
    }

    errorAttributes[MMEEventKeyModel] = NSProcessInfo.mme_deviceModel;
    errorAttributes[MMEEventKeyOSVersion] = NSProcessInfo.mme_osVersion;
    errorAttributes[MMEEventKeyDevice] = NSProcessInfo.mme_hardwareModel;

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

// MARK: - Location Event

+(instancetype)locationEventWithID:(NSString*)identifier
                          location:(CLLocation*)location
                            source:(NSString*)source
                   operatingSystem:(NSString*)operatingSystem
                  applicationState:(nullable NSString*)applicationState {

    NSMutableDictionary* attributes = [@{
        MMEEventKeyEvent: MMEEventTypeLocation,
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
        MMEEventKeySource: source,
        MMEEventKeySessionId: identifier,
        MMEEventKeyOperatingSystem: operatingSystem,
        MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
        MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
        MMEEventKeyAltitude: @([location mme_roundedAltitude]),
        MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy]),
        MMEEventKeyVerticalAccuracy: @([location mme_roundedVerticalAccuracy]),
        MMEEventKeySpeed: @([location mme_roundedSpeed]),
        MMEEventKeyCourse: @([location mme_roundedCourse])
    } mutableCopy];

    if ([location floor]) {
        [attributes setValue:@([location floor].level) forKey:MMEEventKeyFloor];
    }

    if (applicationState) {
        attributes[MMEEventKeyApplicationState] = applicationState;
    }
    return [self eventWithAttributes:attributes];
}

+ (instancetype)locationEventWithID:(NSString*)identifier
                           location:(CLLocation*)location {

    NSString* applicationState = nil;
    if (![NSProcessInfo.mme_applicationState isEqualToString:MMEApplicationStateUnknown]) {
        applicationState = NSProcessInfo.mme_applicationState;
    }

    return [self locationEventWithID:identifier
                            location:location
                              source:MMEEventSource
                     operatingSystem:NSProcessInfo.mme_osVersion
                    applicationState:applicationState];
}

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes
                          instanceIdentifer:(NSString *)instanceIdentifer
                            commonEventData:(MMECommonEventData *)commonEventData {
    NSMutableDictionary *eventAttributes = attributes.mutableCopy;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeLocation;
    eventAttributes[MMEEventKeySource] = MMEEventSource;
    eventAttributes[MMEEventKeySessionId] = instanceIdentifer;
    eventAttributes[MMEEventKeyOperatingSystem] = NSProcessInfo.mme_osVersion;
    if (![NSProcessInfo.mme_applicationState isEqualToString:MMEApplicationStateUnknown]) {
        eventAttributes[MMEEventKeyApplicationState] = NSProcessInfo.mme_applicationState;
    }

    return [self eventWithAttributes:eventAttributes];
}

// MARK: - MapLoad

+ (instancetype)mapLoadEventWithCreatedDate:(NSDate*)createdDate
                               vendorID:(NSString*)vendorID
                            deviceModel:(NSString*)deviceModel
                            operatingSystem:(NSString*)operatingSystem
                            screenScale:(NSNumber*)screenScale
                              fontScale:(nullable NSNumber*)fontScale
                      deviceOrientation:(nullable NSString*)deviceOrientation
                     isReachableViaWiFi:(BOOL)isReachableViaWiFi {

    // Required Params
    NSMutableDictionary *attributes = [@{
        MMEEventKeyEvent: MMEEventTypeMapLoad,
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:createdDate],
        MMEEventKeyVendorID: vendorID,
        MMEEventKeyModel: deviceModel,
        MMEEventKeyOperatingSystem: operatingSystem,
        MMEEventKeyResolution: screenScale,
        MMEEventKeyWifi: @(isReachableViaWiFi)
    } mutableCopy];

    // Optional Params
    if (fontScale){
        attributes[MMEEventKeyAccessibilityFontScale] = fontScale;
    }

    if (deviceOrientation){
        attributes[MMEEventKeyOrientation] = deviceOrientation;
    }

    return [MMEEvent eventWithAttributes:attributes];
}

+ (instancetype)mapLoadEvent {
    NSDate *createdDate = NSDate.new;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    NSNumber* fontScale = nil;

    if (NSBundle.mme_isExtension) {
        fontScale = @(NSExtensionContext.mme_contentSizeScale);
    } else {
        fontScale = @(UIApplication.sharedApplication.mme_contentSizeScale);
    }

#endif

    // Fallthrough to Designated Initializer
    return [self mapLoadEventWithCreatedDate:createdDate
                                    vendorID:NSProcessInfo.mme_vendorId
                                 deviceModel:NSProcessInfo.mme_deviceModel
                             operatingSystem:NSProcessInfo.mme_osVersion
                                 screenScale: @(NSProcessInfo.mme_screenScale)
#if TARGET_OS_IOS || TARGET_OS_TVOS

                                   fontScale:fontScale
                           deviceOrientation:UIDevice.currentDevice.mme_deviceOrientation
#else
                                   fontScale:nil
                           deviceOrientation:nil
#endif
                          isReachableViaWiFi:MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi];
}

/*! Deprecated Convenience MapLoad Event Iniitalizer */
+ (instancetype)mapLoadEventWithDateString:(NSDate *)dateString
                           commonEventData:(nullable MMECommonEventData *)commonEventData {
    NSMutableDictionary *eventAttributes = NSMutableDictionary.dictionary;
    eventAttributes[MMEEventKeyEvent] = MMEEventTypeMapLoad;
    eventAttributes[MMEEventKeyCreated] = dateString;
    eventAttributes[MMEEventKeyVendorID] = NSProcessInfo.mme_vendorId;
    eventAttributes[MMEEventKeyModel] = NSProcessInfo.mme_deviceModel;
    eventAttributes[MMEEventKeyOperatingSystem] = NSProcessInfo.mme_osVersion;
    eventAttributes[MMEEventKeyResolution] = @(NSProcessInfo.mme_screenScale);
#if TARGET_OS_IOS || TARGET_OS_TVOS

    if (NSBundle.mme_isExtension) {
        eventAttributes[MMEEventKeyAccessibilityFontScale] = @(NSExtensionContext.mme_contentSizeScale);
    } else {
        eventAttributes[MMEEventKeyAccessibilityFontScale] = @(UIApplication.sharedApplication.mme_contentSizeScale);
    }
    eventAttributes[MMEEventKeyOrientation] = UIDevice.currentDevice.mme_deviceOrientation;
#endif
    eventAttributes[MMEEventKeyWifi] = @(MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi);

    return [MMEEvent eventWithAttributes:eventAttributes];
}

// MARK: - Map Tap Event

/*! @Brief Designated Map TapEvent Initializer*/
+(instancetype)mapTapEventWithCreatedDate:(NSDate*)createdDate
                        deviceOrientation:(nullable NSString*)deviceOrientation
                       isReachableViaWiFi:(BOOL)isReachableViaWiFi {
    NSMutableDictionary* attributes = [@{
        MMEEventKeyEvent: MMEEventTypeMapTap,
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:createdDate],
        MMEEventKeyWifi: @(isReachableViaWiFi)
    } mutableCopy];

#if TARGET_OS_IOS || TARGET_OS_TVOS
    attributes[MMEEventKeyOrientation] = deviceOrientation;
#endif

    return [MMEEvent eventWithAttributes:attributes];
}

/*! @Brief Convenience Map TapEvent Initializer*/
+(instancetype)mapTapEvent {

    NSDate *createdDate = NSDate.new;

    NSString* deviceOrientation = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    deviceOrientation = UIDevice.currentDevice.mme_deviceOrientation;
#endif
    return [self mapTapEventWithCreatedDate:createdDate
                          deviceOrientation:deviceOrientation
                         isReachableViaWiFi:MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi];
}

/*! @brief Deprecated Convenience Initializer */
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

// MARK: - MapDrag

/*! @Brief MapDrag Event Designated Initializer */
+ (instancetype)mapDragEndEventWithCreatedDate:(NSDate*)createdDate
                             deviceOrientation:(nullable NSString*)deviceOrientation
                            isReachableViaWiFi:(BOOL)isReachableViaWiFi {

    NSMutableDictionary* attributes = [@{
        MMEEventKeyEvent: MMEEventTypeMapDragEnd,
        MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:createdDate],
        MMEEventKeyWifi: @(isReachableViaWiFi)
    } mutableCopy];

#if TARGET_OS_IOS || TARGET_OS_TVOS
    attributes[MMEEventKeyOrientation] = deviceOrientation;
#endif

    return [MMEEvent eventWithAttributes:attributes];
}

/*! @Brief Convenience MapDrag Event Initializer*/
+(instancetype)mapDragEndEvent {

    NSDate *createdDate = NSDate.new;
    NSString* deviceOrientation = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    deviceOrientation = UIDevice.currentDevice.mme_deviceOrientation;
#endif
    return [self mapDragEndEventWithCreatedDate:createdDate
                          deviceOrientation:deviceOrientation
                         isReachableViaWiFi:MMEReachability.reachabilityForLocalWiFi.isReachableViaWiFi];
}

/*! Deprecated Convenience MapDrag Event Iniitalizer */
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

            // TODO: - if this is a nullable type perhaps this could expose an error/exception for reporting outside the init
            // for known behaviors
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
