#import "UIKit+MMEMobileEvents.h"

@implementation NSObject (MMEMobileEvents)

void mme_linkUIKitCategories(){}

@end

// MARK: -

@implementation UIDevice (MMEMobileEvents)

- (NSString *)mme_deviceOrientation {
    NSString *result;
    switch (self.orientation) {
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

@end

// MARK: -

@implementation UIApplication (MMEMobileEvents)

- (NSInteger)mme_contentSizeScaleFor:(UIContentSizeCategory)category {
    NSInteger result = -9999;

    if ([category isEqualToString:UIContentSizeCategoryExtraSmall]) {
        result = -3;
    } else if ([category isEqualToString:UIContentSizeCategorySmall]) {
        result = -2;
    } else if ([category isEqualToString:UIContentSizeCategoryMedium]) {
        result = -1;
    } else if ([category isEqualToString:UIContentSizeCategoryLarge]) {
        result = 0;
    } else if ([category isEqualToString:UIContentSizeCategoryExtraLarge]) {
        result = 1;
    } else if ([category isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
        result = 2;
    } else if ([category isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
        result = 3;
    } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityMedium]) {
        result = 9;
    } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityLarge]) {
        result = 10;
    } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge]) {
        result = 11;
    } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
        result = 12;
    } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
        result = 13;
    }

    return result;
}

- (NSInteger)mme_contentSizeScale {
    return [self mme_contentSizeScaleFor:self.preferredContentSizeCategory];
}

@end

@implementation NSExtensionContext (MMEMobileEvents)

+ (NSInteger)mme_contentSizeForTraitCollection:(UITraitCollection*)traitCollection {
    NSInteger result = -9999;

    if (@available(iOS 10, *)) {
        NSString *category = traitCollection.preferredContentSizeCategory;

        if ([category isEqualToString:UIContentSizeCategoryExtraSmall]) {
            result = -3;
        } else if ([category isEqualToString:UIContentSizeCategorySmall]) {
            result = -2;
        } else if ([category isEqualToString:UIContentSizeCategoryMedium]) {
            result = -1;
        } else if ([category isEqualToString:UIContentSizeCategoryLarge]) {
            result = 0;
        } else if ([category isEqualToString:UIContentSizeCategoryExtraLarge]) {
            result = 1;
        } else if ([category isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
            result = 2;
        } else if ([category isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
            result = 3;
        } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityMedium]) {
            result = 9;
        } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityLarge]) {
            result = 10;
        } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge]) {
            result = 11;
        } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
            result = 12;
        } else if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
            result = 13;
        }
    } else {
        // No-Op
    }

    return result;
}

+ (NSInteger)mme_contentSizeScale {
    return [self mme_contentSizeForTraitCollection:UIScreen.mainScreen.traitCollection];
}

@end
