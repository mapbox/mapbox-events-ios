#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (MMEMobileEvents)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
void mme_linkUIKitCategories();
#pragma clang diagnostic pop

@end

#pragma mark -

#if TARGET_OS_IPHONE
@interface UIDevice (MMEMobileEvents)

- (NSString *)mme_deviceOrientation;

@end

#pragma mark -

@interface UIApplication (MMEMobileEvents)

- (NSInteger)mme_contentSizeScale;

@end
#endif

@interface NSExtensionContext (MMEMobileEvents)

+ (NSInteger)mme_contentSizeScale;

@end

NS_ASSUME_NONNULL_END
