#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol MMELocationManagerDelegate;
@protocol MMEEventConfigProviding;

// MARK: - Block Types

typedef void(^OnDidExitRegion)(CLRegion* region);
typedef void(^OnDidUpdateCoordinate)(CLLocationCoordinate2D coordinate);

extern const CLLocationDistance MMELocationManagerDistanceFilter;
extern const CLLocationDistance MMELocationManagerHibernationRadius;
extern NSString * const MMELocationManagerRegionIdentifier;

// MARK: - MMELocationManager

@protocol MMELocationManager <NSObject>
@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;

/*! Starts the generation of updates that report the user’s current location. */
- (void)startUpdatingLocation;

/*! Stops the generation of location updates. */
- (void)stopUpdatingLocation;

@end

@interface MMELocationManager : NSObject <MMELocationManager>

// MARK: - Properties

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;

// MARK: - Initializers

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config;

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                      onDidExitRegion:(OnDidExitRegion)onDidExitRegion
                onDidUpdateCoordinate:(OnDidUpdateCoordinate)onDidUpdateCoordinate NS_DESIGNATED_INITIALIZER;

/*! Starts the generation of updates that report the user’s current location. */
- (void)startUpdatingLocation;

/*! Stops the generation of location updates. */
- (void)stopUpdatingLocation;

@end

// MARK: - MMELocationManagerDelegate

@protocol MMELocationManagerDelegate <NSObject>

@optional

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations;
- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager;
- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager;
- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager;
- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager;
- (void)locationManager:(MMELocationManager *)locationManager didVisit:(CLVisit *)visit;

@end
