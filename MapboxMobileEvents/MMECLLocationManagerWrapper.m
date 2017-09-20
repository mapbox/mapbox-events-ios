#import "MMECLLocationManagerWrapper.h"
#import "NSBundle+MMEAdditions.h"

@interface MMECLLocationManagerWrapper ()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation MMECLLocationManagerWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return self;
}

- (CLAuthorizationStatus)authorizationStatus {
    return [CLLocationManager authorizationStatus];
}

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (void)startMonitoringSignificantLocationChanges {
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopMonitoringSignificantLocationChanges {
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)startMonitoringForRegion:(CLRegion *)region {
    [self.locationManager startMonitoringForRegion:region];
}

- (void)stopMonitoringForRegion:(CLRegion *)region {
    [self.locationManager stopMonitoringForRegion:region];
}

- (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates {
    if ([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
        if ([[NSBundle mainBundle] allowsBackgroundLocationMode]) {
            self.locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
        }
    }
}

- (BOOL)allowsBackgroundLocationUpdates {
    if ([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
        return [[NSBundle mainBundle] allowsBackgroundLocationMode] ? self.locationManager.allowsBackgroundLocationUpdates : NO;
    }
    return NO;
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    self.locationManager.desiredAccuracy = desiredAccuracy;
}

- (CLLocationAccuracy)desiredAccuracy {
    return self.locationManager.desiredAccuracy;
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    self.locationManager.distanceFilter = distanceFilter;
}

- (CLLocationDistance)distanceFilter {
    return self.locationManager.distanceFilter;
}

- (NSSet *)monitoredRegions {
    return self.locationManager.monitoredRegions;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.delegate locationManagerWrapper:self didChangeAuthorizationStatus:status];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self.delegate locationManagerWrapper:self didUpdateLocations:locations];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.delegate locationManagerWrapper:self didExitRegion:region];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    [self.delegate locationManagerWrapperDidPauseLocationUpdates:self];
}

@end
