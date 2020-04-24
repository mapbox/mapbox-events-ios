#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (MMEMobileEvents)

+ (BOOL)mme_isExtension;

// MapboxMobileEvents Bundle
+ (NSBundle*)mme_bundle;

@end

NS_ASSUME_NONNULL_END
