@import Foundation;

@class CLLocationManager;

/// Preconfigured Dependency Builder
@protocol MMEDependencyProviding <NSObject>

/// Generates a new LocationManager Instance
- (CLLocationManager *)locationManagerInstance;

@end
