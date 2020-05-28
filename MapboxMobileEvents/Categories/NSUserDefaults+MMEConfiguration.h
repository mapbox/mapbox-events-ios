@import Foundation;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

// MARK: -

@class MMEDate;

@interface NSUserDefaults (MMEConfiguration)

/// the shared NSUserDefaults object with the MMEConfigurationDomain loaded and our defaults registered
+ (instancetype)mme_configuration;

@end

NS_ASSUME_NONNULL_END
