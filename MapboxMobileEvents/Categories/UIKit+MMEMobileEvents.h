#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MMEMobileEvents)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
void mme_linkUIKitCategories();
#pragma clang diagnostic pop

@end

// MARK: -

@interface UIDevice (MMEMobileEvents)

/*! @brief Mapbox DeviceOrientation Value*/
- (NSString *)mme_deviceOrientation;

@end

// MARK: -

@interface UIApplication (MMEMobileEvents)

/*! @brief Convenience ContentSizeScale for Application */
- (NSInteger)mme_contentSizeScale;

/*! @brief Content SizeScale for category*/
- (NSInteger)mme_contentSizeScaleFor:(UIContentSizeCategory)category;

@end

@interface NSExtensionContext (MMEMobileEvents)

/*! @brief Content Size Scale for UIDevice (Useful for determining sizing for Extensions */
+ (NSInteger)mme_contentSizeForTraitCollection:(UITraitCollection*)traitCollection;

/*! @brief Content SizeScale for category defaulting to UIDevice's traits  */
+ (NSInteger)mme_contentSizeScale;

@end

NS_ASSUME_NONNULL_END
