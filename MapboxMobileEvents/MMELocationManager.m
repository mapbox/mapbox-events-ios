#import <CoreLocation/CoreLocation.h>
#import "MMEDependencyManager.h"
#import "MMELocationManager.h"
#import "MMEUIApplicationWrapper.h"
#import "MMEEventConfigProviding.h"

static const NSTimeInterval MMELocationManagerHibernationTimeout = 300.0;
static const NSTimeInterval MMELocationManagerHibernationPollInterval = 5.0;

const CLLocationDistance MMELocationManagerDistanceFilter = 5.0;
const CLLocationDistance MMELocationManagerRegionCenterDistanceFilter = 5.0;
const CLLocationDistance MMERadiusAccuracyMax = 300.0;

NSString * const MMELocationManagerRegionIdentifier = @"MMELocationManagerRegionIdentifier.fence.center";

@interface MMELocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) id<MMEUIApplicationWrapper> application;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, getter=isUpdatingLocation, readwrite) BOOL updatingLocation;
@property (nonatomic, strong) NSDate *backgroundLocationServiceTimeoutAllowedDate;
@property (nonatomic, strong) NSTimer *backgroundLocationServiceTimeoutTimer;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;
@property (nonatomic, strong) MMEDependencyManager * dependencyManager;
@property (nonatomic, strong) id <MMEEventConfigProviding> config;
@property (nonatomic, copy) OnDidExitRegion onDidExitRegion;
@property (nonatomic, copy) OnDidUpdateCoordinate onDidUpdateCoordinate;

@end

@implementation MMELocationManager

- (void)dealloc {
    _locationManager.delegate = nil;
}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config {
    return [self initWithConfig:config
                onDidExitRegion:^(CLRegion* region) {}
          onDidUpdateCoordinate:^(CLLocationCoordinate2D coordinate) {}];
}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
                      onDidExitRegion:(OnDidExitRegion)onDidExitRegion
                onDidUpdateCoordinate:(OnDidUpdateCoordinate)onDidUpdateCoordinate {
    self = [super init];
    if (self) {
        _application = [[MMEUIApplicationWrapper alloc] init];
        NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
        self.hostAppHasBackgroundCapability = [backgroundModes containsObject:@"location"];
        self.dependencyManager = [[MMEDependencyManager alloc] init];
        self.config = config;
        self.onDidExitRegion = onDidExitRegion;
        self.onDidUpdateCoordinate = onDidUpdateCoordinate;
    }
    return self;
}

- (void)startUpdatingLocation {
    if (![CLLocationManager locationServicesEnabled]) {
        return;
    }
    if ([self isUpdatingLocation]) {
        return;
    }

    self.locationManager = [self.dependencyManager locationManagerInstance];
    [self configurePassiveLocationManager];
    [self startLocationServices];
}

- (void)stopUpdatingLocation {
    if ([self isUpdatingLocation]) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
        [self.locationManager stopMonitoringVisits];
        self.updatingLocation = NO;
        if ([self.delegate respondsToSelector:@selector(locationManagerDidStopLocationUpdates:)]) {
            [self.delegate locationManagerDidStopLocationUpdates:self];
        }
        [self stopMonitoringRegions];
        self.locationManager = nil;
    }
}

- (void)setLocationManager:(CLLocationManager *)locationManager {
    id<CLLocationManagerDelegate> delegate = _locationManager.delegate;
    _locationManager.delegate = nil;
    _locationManager = locationManager;
    _locationManager.delegate = delegate;
}

- (void)stopMonitoringRegions {
    for(CLRegion *region in self.locationManager.monitoredRegions) {
        if([region.identifier isEqualToString:MMELocationManagerRegionIdentifier]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void)setMetricsEnabledForInUsePermissions:(BOOL)metricsEnabledForInUsePermissions {
    _metricsEnabledForInUsePermissions = metricsEnabledForInUsePermissions;
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse && self.hostAppHasBackgroundCapability) {
        if (@available(iOS 9.0, *)) {
            self.locationManager.allowsBackgroundLocationUpdates = self.isMetricsEnabledForInUsePermissions;
        }
    }
}

// MARK: - Utilities

- (void)configurePassiveLocationManager {
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.locationManager.distanceFilter = MMELocationManagerDistanceFilter;
}

- (void)startLocationServices {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    
    BOOL authorizedAlways = authorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
    
    if (authorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        // If the host app can run in the background with `always` location permissions then allow background
        // updates and start the significant location change service and background timeout timer
        if (authorizedAlways && self.hostAppHasBackgroundCapability) {
            [self.locationManager startMonitoringSignificantLocationChanges];
            [self startBackgroundTimeoutTimer];
            if (@available(iOS 9.0, *)) {
                self.locationManager.allowsBackgroundLocationUpdates = YES;
            }
        }
        
        // If authorization status is when in use specifically, allow background location updates based on
        // if the library is configured to do so. Don't worry about significant location change and the
        // background timer (just above) since all use cases for background collection with in use only
        // permissions involve navigation where a user would want and expect the app to be running / navigating
        // even if it is not in the foreground
        if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse && self.hostAppHasBackgroundCapability) {
            if (@available(iOS 9.0, *)) {
                self.locationManager.allowsBackgroundLocationUpdates = self.isMetricsEnabledForInUsePermissions;
            }
        }
        
        if (authorizedAlways) {
            [self.locationManager startMonitoringVisits];
        }

        [self.locationManager startUpdatingLocation];
        self.updatingLocation = YES;
        
        if ([self.delegate respondsToSelector:@selector(locationManagerDidStartLocationUpdates:)]) {
            [self.delegate locationManagerDidStartLocationUpdates:self];
        }
    }
}

- (void)timeoutAllowedCheck {
    if (!self.isUpdatingLocation) {
        return;
    }
    
    if (self.application.applicationState == UIApplicationStateActive ||
        self.application.applicationState == UIApplicationStateInactive ) {
        [self startBackgroundTimeoutTimer];
        return;
    }
    
    NSTimeInterval timeIntervalSinceTimeoutAllowed = [[NSDate date] timeIntervalSinceDate:self.backgroundLocationServiceTimeoutAllowedDate];
    if (timeIntervalSinceTimeoutAllowed > 0) {
        [self.locationManager stopUpdatingLocation];
        self.backgroundLocationServiceTimeoutAllowedDate = nil;
        if ([self.delegate respondsToSelector:@selector(locationManagerBackgroundLocationUpdatesDidTimeout:)]) {
            [self.delegate locationManagerBackgroundLocationUpdatesDidTimeout:self];
        }
    }
}

- (void)startBackgroundTimeoutTimer {
    NSTimer *tempTimer = self.backgroundLocationServiceTimeoutTimer;
    self.backgroundLocationServiceTimeoutAllowedDate = [[NSDate date] dateByAddingTimeInterval:MMELocationManagerHibernationTimeout];
    self.backgroundLocationServiceTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:MMELocationManagerHibernationPollInterval target:self selector:@selector(timeoutAllowedCheck) userInfo:nil repeats:YES];
    [tempTimer invalidate];
}

- (void)establishRegionMonitoringForLocation:(CLLocation *)location {
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate
                                                                 radius:self.config.backgroundGeofence
                                                             identifier:MMELocationManagerRegionIdentifier];
    region.notifyOnEntry = NO;
    region.notifyOnExit = YES;
    [self.locationManager startMonitoringForRegion:region];
}

// MARK: - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)locationManager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    if (location.speed > 0.0) {
        [self startBackgroundTimeoutTimer];
    }
    if ([self.locationManager.monitoredRegions anyObject] == nil) {
        [self establishRegionMonitoringForLocation:location];
    }
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [self.delegate locationManager:self didUpdateLocations:locations];
    }

    self.onDidUpdateCoordinate(location.coordinate);

    if (location.horizontalAccuracy < MMERadiusAccuracyMax) {
        for(CLRegion *region in self.locationManager.monitoredRegions) {
            if([region.identifier isEqualToString:MMELocationManagerRegionIdentifier]) {
                CLCircularRegion *circularRegion = (CLCircularRegion *)region;
                CLLocation *regionCenterLocation = [[CLLocation alloc] initWithLatitude:circularRegion.center.latitude longitude:circularRegion.center.longitude];
                if ([regionCenterLocation distanceFromLocation:location] > MMELocationManagerRegionCenterDistanceFilter) {
                    [self establishRegionMonitoringForLocation:location];
                }
                return;
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)locationManager didExitRegion:(CLRegion *)region {
    [self startBackgroundTimeoutTimer];
    [self.locationManager startUpdatingLocation];
    self.onDidExitRegion(region);
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if ([self.delegate respondsToSelector:@selector(locationManager:didVisit:)]) {
        [self.delegate locationManager:self didVisit:visit];
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)locationManager {
    if ([self.delegate respondsToSelector:@selector(locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:)]) {
        [self.delegate locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:self];
    }
}

@end

