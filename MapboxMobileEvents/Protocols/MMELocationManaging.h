#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol MMELocationManagerDelegate;

// MARK: - MMELocationManager

@protocol MMELocationManaging <NSObject>

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;

/*! Starts the generation of updates that report the user’s current location. */
- (void)startUpdatingLocation;

/*! Stops the generation of location updates. */
- (void)stopUpdatingLocation;

@end
