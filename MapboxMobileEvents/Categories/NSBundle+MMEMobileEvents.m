#import "NSBundle+MMEMobileEvents.h"


@interface MMEBundle: NSObject
@end

@implementation MMEBundle
@end

@implementation NSBundle (MMEMobileEvents)

+ (BOOL)mme_isExtension {
    return [NSBundle.mainBundle.bundleURL.pathExtension isEqualToString:@"appex"];
}

+ (NSBundle*)mme_bundle {
    return [NSBundle bundleForClass:MMEBundle.self];
}

@end
