#import "NSProcessInfo+SystemInfo.h"
#import "MMEEventsManager.h"
#import "MMEPreferences.h"
#import "MMEConstants.h"

#if TARGET_OS_IOS || TARGET_OS_TVOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_MACOS
#import <AppKit/AppKit.h>
#endif

#include <sys/sysctl.h>

NSString * const MMEApplicationStateForeground = @"Foreground";
NSString * const MMEApplicationStateBackground = @"Background";
NSString * const MMEApplicationStateInactive = @"Inactive";
NSString * const MMEApplicationStateUnknown = @"Unknown";

@implementation NSProcessInfo (SystemInfo)

+ (NSString *)sysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);
    return results;
}

+ (NSString *)mme_platformName {
    NSString *result;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    result = MMEEventKeyiOS;
#elif TARGET_OS_MACOS
    result = MMEEventKeyMac;
#else
    result = MMEEventUnknown;
#endif
    
    return result;
}

+ (NSString *)mme_applicationState {
#if TARGET_OS_IOS || TARGET_OS_TVOS
    switch (UIApplication.sharedApplication.applicationState) {
        case UIApplicationStateActive:
            return MMEApplicationStateForeground;
        case UIApplicationStateInactive:
            return MMEApplicationStateInactive;
        case UIApplicationStateBackground:
            return MMEApplicationStateBackground;
        default:
            return MMEApplicationStateUnknown;
    }
#else
    return MMEApplicationStateUnknown;
#endif
}

+ (NSString *)mme_osVersion {
    NSString *osVersion = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    osVersion = [NSString stringWithFormat:@"%@ %@", UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion];
#elif TARGET_OS_MACOS
    osVersion = NSProcessInfo.processInfo.operatingSystemVersionString;
#endif
    return osVersion;
}

// MARK: - iOS Specific System Info

+ (NSString *)mme_hardwareModel {
    NSString *modelName = nil;
    modelName = [self sysInfoByName:"hw.machine"]; 
    return modelName;
}

+ (NSString *)mme_deviceModel {
    NSString *deviceModel = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    deviceModel = UIDevice.currentDevice.model;
#else
    deviceModel = [self sysInfoMyName:"hw.targettype"];
#endif
    return deviceModel;
}

+ (NSString *)mme_vendorId {
    NSString *vendorId = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    vendorId = UIDevice.currentDevice.identifierForVendor.UUIDString;
#else
    vendorId = MMEEventsManager.sharedManager.configuration.clientId;
#endif
    return vendorId;
}

+ (CGFloat)mme_screenScale {
    CGFloat screenScale = 0;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
        screenScale = UIScreen.mainScreen.nativeScale;
    } else {
        screenScale = UIScreen.mainScreen.scale;
    }
#elif TARGET_OS_MACOS
    screenScale = NSScreen.mainScreen.backingScaleFactor
#endif
    return screenScale;
}

@end
