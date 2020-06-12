#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MMELocationManaging.h"

@protocol MMELocationManagerDelegate;
@protocol MMEConfigurationProviding;
@protocol MMEUIApplicationWrapper;
@protocol MMELocationManaging;

// MARK: - Block Types

typedef void(^OnDidExitRegion)(CLRegion* region);
typedef void(^OnDidUpdateCoordinate)(CLLocationCoordinate2D coordinate);

extern const CLLocationDistance MMELocationManagerDistanceFilter;
extern const CLLocationDistance MMELocationManagerHibernationRadius;
extern NSString * const MMELocationManagerRegionIdentifier;

/*!
 @Brief Location Manager Wrapper which applies configurations based on config/bundle
 */
@interface MMELocationManager : NSObject <MMELocationManaging>

// MARK: - Properties

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;

// MARK: - Initializers

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config;

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config
               locationManager:(CLLocationManager*)locationManager;

- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config
               locationManager:(CLLocationManager*)locationManager
                        bundle:(NSBundle*)bundle;
/*!
 @Brief Designated Initializer
 @param config Configuration driving Differentiated behaviors
 @param locationManager Location Manager instance to be utilized for collecting data
 @param bundle Source of Info Dictionary Key/Values
 @param application Application Wrapper (State/background task interface)
 */
- (instancetype)initWithConfig:(id <MMEConfigurationProviding>)config
               locationManager:(CLLocationManager*)locationManager
                        bundle:(NSBundle*)bundle
                   application:(id <MMEUIApplicationWrapper>)application NS_DESIGNATED_INITIALIZER;

/*! Starts the generation of updates that report the user’s current location. */
- (void)startUpdatingLocation;

/*! Stops the generation of location updates. */
- (void)stopUpdatingLocation;

// MARK: - Listeners

/*! @brief Block called onDidExitRegion Events  */
- (void)registerOnDidExitRegion:(OnDidExitRegion)onDidExitRegion;

/*! @brief Block called onDidUpdateCoordinate Events  */
- (void)registerOnDidUpdateCoordinate:(OnDidUpdateCoordinate)onDidUpdateCoordinate;

@end

// MARK: - MMELocationManagerDelegate

@protocol MMELocationManagerDelegate <NSObject>

@optional

/*!
 @Brief Tells the delegate that new location data is available.
 @param locationManager The location manager object reporting the event.
 @param locations An array of CLLocation objects containing the location data. This array always contains at least one object representing the current location. If updates were deferred or if multiple locations arrived before they could be delivered, the array may contain additional entries. The objects in the array are organized in the order in which they occurred. Therefore, the most recent location update is at the end of the array.
 */
- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations;

/*!
 @Brief Called upon the successful start of location updates
 @param locationManager The location manager object reporting the event.
 @Discussion MMELocationManager inspects state after startLocationUpdates which evaluates current state which may prevent further execution.
 If all prerequisites are successful, this method is called.
 */
- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager;

/*!
 @Brief Called upon the successful start of location updates
 @param locationManager The location manager object reporting the event.
 */
- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager;

/*!
 Tells the delegate that location updates were paused.
 @param locationManager The location manager object that paused the delivery of events.
 */
- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager;

/*!
 Tells the delegate that location updates were stopped.
 @param locationManager The location manager object that paused the delivery of events.
 */
- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager;

/*!
 @Brief Tells the delegate that a new visit-related event was received.
 @param locationManager The location manager object reporting the event.
 @param visit The visit object that contains the information about the event.
 */
- (void)locationManager:(MMELocationManager *)locationManager didVisit:(CLVisit *)visit;

@end
