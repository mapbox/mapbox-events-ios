#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "UIKit+MMEMobileEvents.h"

// MARK: - Mock Classes

// MARK: Mock Device

@interface MockDevice : UIDevice
@property (nonatomic, assign) UIDeviceOrientation mockOrientation;

-(instancetype)initWithOrientation:(UIDeviceOrientation)orientation;
@end

@implementation MockDevice

-(instancetype)initWithOrientation:(UIDeviceOrientation)orientation {
    if (self = [super init]) {
        self.mockOrientation = orientation;
    }
    return self;
}

- (UIDeviceOrientation)orientation {
    return _mockOrientation;
}

@end

// MARK: Mock TraitCollections

@interface MockTraitCollectionExtraSmall: UITraitCollection
@end
@implementation MockTraitCollectionExtraSmall
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryExtraSmall;
}
@end

@interface MockTraitCollectionSmall: UITraitCollection
@end
@implementation MockTraitCollectionSmall
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategorySmall;
}
@end

@interface MockTraitCollectionMedium: UITraitCollection
@end
@implementation MockTraitCollectionMedium
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryMedium;
}
@end

@interface MockTraitCollectionLarge: UITraitCollection
@end
@implementation MockTraitCollectionLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryLarge;
}
@end

@interface MockTraitCollectionExtraLarge: UITraitCollection
@end
@implementation MockTraitCollectionExtraLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryExtraLarge;
}
@end

@interface MockTraitCollectionExtraExtraLarge: UITraitCollection
@end
@implementation MockTraitCollectionExtraExtraLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryExtraExtraLarge;
}
@end

@interface MockTraitCollectionExtraExtraExtraLarge: UITraitCollection
@end
@implementation MockTraitCollectionExtraExtraExtraLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryExtraExtraExtraLarge;
}
@end

@interface MockTraitCollectionAccessibilityMedium: UITraitCollection
@end
@implementation MockTraitCollectionAccessibilityMedium
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryAccessibilityMedium;
}
@end

@interface MockTraitCollectionAccessibilityLarge: UITraitCollection
@end
@implementation MockTraitCollectionAccessibilityLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryAccessibilityLarge;
}
@end

@interface MockTraitCollectionAccessibilityExtraLarge: UITraitCollection
@end
@implementation MockTraitCollectionAccessibilityExtraLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryAccessibilityExtraLarge;
}
@end

@interface MockTraitCollectionAccessibilityExtraExtraLarge: UITraitCollection
@end
@implementation MockTraitCollectionAccessibilityExtraExtraLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryAccessibilityExtraExtraLarge;
}
@end

@interface MockTraitCollectionAccessibilityExtraExtraExtraLarge: UITraitCollection
@end
@implementation MockTraitCollectionAccessibilityExtraExtraExtraLarge
- (UIContentSizeCategory)preferredContentSizeCategory {
    return UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;
}
@end


// MARK: - Tests


@interface UIKitTests : XCTestCase

@end

@implementation UIKitTests



// MARK: - Device
-(void)testDeviceOrientation {
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationUnknown].mme_deviceOrientation, @"Unknown");
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationPortrait].mme_deviceOrientation, @"Portrait");
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationPortraitUpsideDown].mme_deviceOrientation, @"PortraitUpsideDown");
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationLandscapeLeft].mme_deviceOrientation, @"LandscapeLeft");
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationLandscapeRight].mme_deviceOrientation, @"LandscapeRight");
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationFaceUp].mme_deviceOrientation, @"FaceUp");
    XCTAssertEqualObjects([[MockDevice alloc] initWithOrientation:UIDeviceOrientationFaceDown].mme_deviceOrientation, @"FaceDown");
}

// MARK: - UIApplication
-(void)testContentSizeScale {

    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryExtraSmall], -3);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategorySmall], -2);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryMedium], -1);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryLarge], 0);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryExtraLarge], 1);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryExtraExtraLarge], 2);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryExtraExtraExtraLarge], 3);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryAccessibilityMedium], 9);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryAccessibilityLarge], 10);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryAccessibilityExtraLarge], 11);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryAccessibilityExtraExtraLarge], 12);
    XCTAssertEqual([UIApplication.sharedApplication mme_contentSizeScaleFor:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge], 13);

}

// MARK: - Extension Content Size Scale Support

-(void)testDeviceContentSizeScale {
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionExtraSmall.new], -3);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionSmall.new], -2);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionMedium.new], -1);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionLarge.new], 0);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionExtraLarge.new], 1);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionExtraExtraLarge.new], 2);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionExtraExtraExtraLarge.new], 3);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionAccessibilityMedium.new], 9);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionAccessibilityLarge.new], 10);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionAccessibilityExtraLarge.new], 11);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionAccessibilityExtraExtraLarge.new], 12);
    XCTAssertEqual([NSExtensionContext mme_contentSizeForTraitCollection:MockTraitCollectionAccessibilityExtraExtraExtraLarge.new], 13);
}

@end


