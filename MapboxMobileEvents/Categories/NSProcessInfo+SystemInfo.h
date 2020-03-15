#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MMEApplicationStateForeground;
extern NSString * const MMEApplicationStateBackground;
extern NSString * const MMEApplicationStateInactive;
extern NSString * const MMEApplicationStateUnknown;

/// Read-only system information properties for MMEEvents
@interface NSProcessInfo (SystemInfo)

/// name of the platform we are running on (iOS, macOS, & c.)
+ (NSString *)mme_platformName;

/// Foreground or Background for iOS apps, Unknown for other platforms
+ (NSString *)mme_applicationState;

/// OS Version String
+ (NSString *)mme_osVersion;

/// System CPU type: x86_64, arm9, etc.
+ (NSString *)mme_hardwareModel;

/// Device Model String: iPhone 11, Mac, etc.
+ (NSString *)mme_deviceModel;

/// Application Vendor Id
+ (NSString *)mme_vendorId;

/// Point to Pixel Scale of the main screen
+ (CGFloat)mme_screenScale;

@end

NS_ASSUME_NONNULL_END
