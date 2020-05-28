#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (MMEMobileEvents)

/*! Provides feedback if the bundle is a member of an extension */
+ (BOOL)mme_isExtension;

/*! MapboxMobileEvents Bundle */
+ (NSBundle*)mme_bundle;

/*! MME Bundle Version String */
- (NSString *)mme_bundleVersionString;

@end

NS_ASSUME_NONNULL_END
