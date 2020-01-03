#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "MMEEvent.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MMEApplicationStateForeground;
extern NSString * const MMEApplicationStateBackground;
extern NSString * const MMEApplicationStateInactive;
extern NSString * const MMEApplicationStateUnknown;

/// Read-only system information properties for MMEEvents
@interface MMEEvent (SystemInfo)

/// name of the platform we are running on (iOS, macOS, & c.)
+ (NSString *)platformName;

/// Foreground or Background for iOS apps, Unknown for other platforms
+ (NSString *)applicationState;

/// OS Version String
+ (NSString *)osVersion;

/// Device Model String (iPhone 11)
+ (NSString *)deviceModel;

/// Application Vendor Id
+ (NSString *)vendorId;

/// Point to Pixel Scale of the main screen
+ (CGFloat)screenScale;

@end

NS_ASSUME_NONNULL_END
