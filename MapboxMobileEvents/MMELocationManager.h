#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol MMELocationManagerDelegate;

@protocol MMELocationManager <NSObject>

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (NSString *)locationAuthorizationString;
- (CLAuthorizationStatus)locationAuthorization;

- (BOOL)isReducedAccuracy;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (NSString *)accuracyAuthorizationString API_AVAILABLE(ios(14.0), macos(11.0), watchos(7.0), tvos(14.0));
#endif
@end

// MARK: -

extern const CLLocationDistance MMELocationManagerDistanceFilter;
extern const CLLocationDistance MMELocationManagerHibernationRadius;
extern NSString *const MMELocationManagerRegionIdentifier;

@interface MMELocationManager : NSObject <MMELocationManager>

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;

@end

// MARK: -

@protocol MMELocationManagerDelegate <NSObject>

@optional

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations;
- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager;
- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager;
- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager;
- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager;
- (void)locationManager:(MMELocationManager *)locationManager didVisit:(CLVisit *)visit;

@end
