#import "MMECommonEventData.h"
#import "MMEConstants.h"
#include <sys/sysctl.h>

NSString * const MMEApplicationStateForeground = @"Foreground";
NSString * const MMEApplicationStateBackground = @"Background";
NSString * const MMEApplicationStateInactive = @"Inactive";
NSString * const MMEApplicationStateUnknown = @"Unknown";

@implementation MMECommonEventData

- (instancetype)init {
    if (self = [super init]) {
        _vendorId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        _model = [self sysInfoByName:"hw.machine"];
        _platform = [self platformInfo];
        _osVersion = [NSString stringWithFormat:@"%@ %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
        _device = [UIDevice currentDevice].name;
        if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
            _scale = [UIScreen mainScreen].nativeScale;
        } else {
            _scale = [UIScreen mainScreen].scale;
        }
    }
    return self;
}

- (NSString *)sysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);
    return results;
}

- (NSString *)applicationState {
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive:
            return MMEApplicationStateForeground;
        case UIApplicationStateInactive:
            return MMEApplicationStateInactive;
        case UIApplicationStateBackground:
            return MMEApplicationStateBackground;
        default:
            return MMEApplicationStateUnknown;
    }
}

- (NSString *)platformInfo {
    NSString *result;
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        result = MMEEventKeyiOS;
    #elif TARGET_OS_MAC
        result = MMEEventKeyMac;
    #else
        result = MMEEventUnknown;
    #endif
    
    return result;
}


@end
