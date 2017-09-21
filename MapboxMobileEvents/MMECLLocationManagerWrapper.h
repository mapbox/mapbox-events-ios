#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol MMECLLocationManagerWrapperDelegate;

@protocol MMECLLocationManagerWrapper <NSObject,
                                       CLLocationManagerDelegate>

@property (nonatomic, weak) id<MMECLLocationManagerWrapperDelegate> delegate;
@property (nonatomic) BOOL allowsBackgroundLocationUpdates;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;
@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic, copy, readonly) NSSet<__kindof CLRegion *> *monitoredRegions;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;

- (CLAuthorizationStatus)authorizationStatus;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;
- (void)startMonitoringForRegion:(CLRegion *)region;
- (void)stopMonitoringForRegion:(CLRegion *)region;

@end

@interface MMECLLocationManagerWrapper : NSObject <MMECLLocationManagerWrapper>

@property (nonatomic, weak) id<MMECLLocationManagerWrapperDelegate> delegate;

@end

@protocol MMECLLocationManagerWrapperDelegate <NSObject>

- (void)locationManagerWrapper:(id<MMECLLocationManagerWrapper>)locationManagerWrapper didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)locationManagerWrapper:(id<MMECLLocationManagerWrapper>)locationManagerWrapper didUpdateLocations:(NSArray<CLLocation *> *)locations;
- (void)locationManagerWrapper:(id<MMECLLocationManagerWrapper>)locationManagerWrapper didExitRegion:(CLRegion *)region;
- (void)locationManagerWrapperDidPauseLocationUpdates:(id<MMECLLocationManagerWrapper>)locationManagerWrapper;

@end
