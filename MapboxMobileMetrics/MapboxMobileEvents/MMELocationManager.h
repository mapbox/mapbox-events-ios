#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MMECLLocationManagerWrapper.h"

@protocol MMELocationManagerDelegate;

extern const CLLocationDistance MMELocationManagerDistanceFilter;
extern const CLLocationDistance MMELocationManagerHibernationRadius;

extern NSString * const MMELocationManagerRegionIdentifier;

@interface MMELocationManager : NSObject <MMECLLocationManagerWrapperDelegate>

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end

@protocol MMELocationManagerDelegate <NSObject>

@optional

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations;
- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager;
- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager;
- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager;
- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager;

@end
