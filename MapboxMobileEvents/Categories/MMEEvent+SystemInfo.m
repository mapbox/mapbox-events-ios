#import "MMEEvent+SystemInfo.h"
#import "MMEConstants.h"
#import "NSUserDefaults+MMEConfiguration.h"

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

@implementation MMEEvent (SystemInfo)

+ (NSString *)sysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);
    return results;
}

+ (NSString *)platformName {
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

+ (NSString *)applicationState {
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

+ (NSString *)osVersion {
    NSString *osVersion = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    osVersion = [NSString stringWithFormat:@"%@ %@", UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion];
#elif TARGET_OS_MACOS
    osVersion = NSProcessInfo.processInfo.operatingSystemVersionString;
#endif
    return osVersion;
}

// MARK: - iOS Specific System Info

+ (NSString *)deviceModel {
    NSString *modelName = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    modelName = UIDevice.currentDevice.model;
#else
    modelName = [self sysInfoByName:"hw.machine"];
#endif
    return modelName;
}

+ (NSString *)vendorId {
    NSString *vendorId = nil;
#if TARGET_OS_IOS || TARGET_OS_TVOS
    vendorId = UIDevice.currentDevice.identifierForVendor.UUIDString;
#endif
    return vendorId;
}

+ (CGFloat)screenScale {
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
