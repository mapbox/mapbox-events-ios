#import "NSBundle+MMEMobileEvents.h"
#import "MMELogger.h"
#import "NSString+MMEVersions.h"

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

- (NSString *)mme_bundleVersionString {
    NSString *bundleVersion = @"0.0.0";

    // check for MGLSemanticVersionString in Mapbox.framework
    if ([self.infoDictionary.allKeys containsObject:@"MGLSemanticVersionString"]) {
        bundleVersion = self.infoDictionary[@"MGLSemanticVersionString"];
        // validate the semver string and log a message
        if (![bundleVersion mme_isSemverString]) {
            MMELog(MMELogWarn, @"InvalidSemverWarning", ([NSString stringWithFormat:@"bundle %@ version string (%@) is not a valid semantic version string: http://semver.org", self, bundleVersion]));
        }
    }
    else if ([self.infoDictionary.allKeys containsObject:@"CFBundleShortVersionString"]) {
        bundleVersion = self.infoDictionary[@"CFBundleShortVersionString"];
    }

    return bundleVersion;
}

@end
