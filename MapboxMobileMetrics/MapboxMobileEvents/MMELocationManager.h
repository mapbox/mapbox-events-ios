#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol MMELocationManagerDelegate;

@interface MMELocationManager : NSObject <CLLocationManagerDelegate>

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
