#import "MMELocationManager.h"
#import "MMEBackgroundLocationServiceTimeoutHandler.h"
#import "MMEUIApplicationWrapper.h"
#import "MMEDependencyManager.h"
#import "MMEEventsService.h"
#import "MMEEventsConfiguration.h"
#import <CoreLocation/CoreLocation.h>

const CLLocationDistance MMELocationManagerDistanceFilter = 5.0;
const CLLocationDistance MMERadiusAccuracyMax = 300.0;

NSString * const MMELocationManagerRegionIdentifier = @"MMELocationManagerRegionIdentifier.fence.center";

@interface MMELocationManager () <CLLocationManagerDelegate, MMEBackgroundLocationServiceTimeoutDelegate>

@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, getter=isUpdatingLocation, readwrite) BOOL updatingLocation;
@property (nonatomic) MMEBackgroundLocationServiceTimeoutHandler *backgroundLocationServiceTimeoutTimerWrapper;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;
@property (nonatomic) MMEEventsConfiguration *configuration;

@end

@implementation MMELocationManager

- (void)dealloc {
    _locationManager.delegate = nil;
    [_backgroundLocationServiceTimeoutTimerWrapper stopTimer];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _application = [[MMEUIApplicationWrapper alloc] init];
        NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
        _hostAppHasBackgroundCapability = [backgroundModes containsObject:@"location"];
        _configuration = [[MMEEventsService sharedService] configuration];

        _backgroundLocationServiceTimeoutTimerWrapper = [[MMEBackgroundLocationServiceTimeoutHandler alloc] initWithApplication:_application];
        _backgroundLocationServiceTimeoutTimerWrapper.delegate = self;
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
    self.locationManager = [[MMEDependencyManager sharedManager] locationManagerInstance];
    [self configurePassiveLocationManager];
    [self startLocationServices];
}

- (void)stopUpdatingLocation {
    if ([self isUpdatingLocation]) {

        // Stop the timer
        [self stopBackgroundTimeoutTimer];

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

#pragma mark - Utilities

- (void)setLocationManager:(CLLocationManager *)locationManager {
    if (locationManager == _locationManager) {
        return;
    }

    _locationManager.delegate = nil;
    _locationManager = locationManager;
}

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

- (void)startBackgroundTimeoutTimer {
    [self.backgroundLocationServiceTimeoutTimerWrapper startTimer];
}

- (void)stopBackgroundTimeoutTimer {
    [self.backgroundLocationServiceTimeoutTimerWrapper stopTimer];
}

- (void)establishRegionMonitoringForLocation:(CLLocation *)location {
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:self.configuration.locationManagerHibernationRadius identifier:MMELocationManagerRegionIdentifier];
    region.notifyOnEntry = NO;
    region.notifyOnExit = YES;
    [self.locationManager startMonitoringForRegion:region];
}

#pragma mark - CLLocationManagerDelegate

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
    if ([self.locationManager.monitoredRegions anyObject] == nil || location.horizontalAccuracy < MMERadiusAccuracyMax) {
        [self establishRegionMonitoringForLocation:location];
    }
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [self.delegate locationManager:self didUpdateLocations:locations];
    }
}

- (void)locationManager:(CLLocationManager *)locationManager didExitRegion:(CLRegion *)region {
    [self startBackgroundTimeoutTimer];
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if ([self.delegate respondsToSelector:@selector(locationManager:didVisit:)]) {
        [self.delegate locationManager:self didVisit:visit];
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)locationManager {
    // TODO: Should we stop the background timer here for completeness?
//  [self stopBackgroundTimeoutTimer];

    if ([self.delegate respondsToSelector:@selector(locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:)]) {
        [self.delegate locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:self];
    }
}

#pragma mark - MMEBackgroundLocationServiceTimeoutDelegate

- (BOOL)timeoutHandlerShouldCheckForTimeout:(__unused MMEBackgroundLocationServiceTimeoutHandler *)handler {
    return self.isUpdatingLocation && (self.application.applicationState == UIApplicationStateBackground);
}

- (void)timeoutHandlerDidTimeout:(__unused MMEBackgroundLocationServiceTimeoutHandler *)handler {
    if ([self.delegate respondsToSelector:@selector(locationManagerBackgroundLocationUpdatesDidTimeout:)]) {
        [self.delegate locationManagerBackgroundLocationUpdatesDidTimeout:self];
    }

    [self.locationManager stopUpdatingLocation];
}

- (void)timeoutHandlerBackgroundTaskDidExpire:(__unused MMEBackgroundLocationServiceTimeoutHandler *)handler {
    // Do we need a delegate method here (i.e. do we need an event for background task expiry?)
    NSAssert(!handler.timer, @"Timer should be nil by this point");

    [self.locationManager stopUpdatingLocation];
}



@end
