#import "NSBundle+MMEMobileEvents.h"

@implementation NSBundle (MMEMobileEvents)

+ (BOOL)mme_isExtension {
    return [NSBundle.mainBundle.bundleURL.pathExtension isEqualToString:@"appex"];
}

@end
