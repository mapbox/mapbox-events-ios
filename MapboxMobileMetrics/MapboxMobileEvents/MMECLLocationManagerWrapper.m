#import "MMECLLocationManagerWrapper.h"

@interface MMECLLocationManagerWrapper ()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation MMECLLocationManagerWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
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
        self.locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
    }
}

- (BOOL)allowsBackgroundLocationUpdates {
    if ([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
        return self.locationManager.allowsBackgroundLocationUpdates;
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

@end
