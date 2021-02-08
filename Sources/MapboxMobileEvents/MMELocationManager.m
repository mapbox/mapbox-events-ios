#import <CoreLocation/CoreLocation.h>

#import "MMEDependencyManager.h"
#import "MMELocationManager.h"
#import "MMEMetricsManager.h"
#import "MMEUIApplicationWrapper.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSBundle+MMEMobileEvents.h"
#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"

static const NSTimeInterval MMELocationManagerHibernationTimeout = 300.0;
static const NSTimeInterval MMELocationManagerHibernationPollInterval = 5.0;

const CLLocationDistance MMELocationManagerDistanceFilter = 5.0;
const CLLocationDistance MMELocationManagerRegionCenterDistanceFilter = 5.0;
const CLLocationDistance MMERadiusAccuracyMax = 300.0;

NSString * const MMELocationManagerRegionIdentifier = @"MMELocationManagerRegionIdentifier.fence.center";

@interface MMELocationManager () <CLLocationManagerDelegate>

@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, getter=isUpdatingLocation, readwrite) BOOL updatingLocation;
@property (nonatomic) NSDate *backgroundLocationServiceTimeoutAllowedDate;
@property (nonatomic) NSTimer *backgroundLocationServiceTimeoutTimer;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;

@end

@implementation MMELocationManager

@synthesize locationManager = _locationManager;

- (void)dealloc {
    _locationManager.delegate = nil;
}

- (CLLocationManager *)locationManager  {
    if (_locationManager == nil) {
        _locationManager = [[MMEDependencyManager sharedManager] locationManagerInstance];
    }
    return _locationManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _application = [[MMEUIApplicationWrapper alloc] init];
        NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
        _hostAppHasBackgroundCapability = [backgroundModes containsObject:@"location"];
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
    }
}

- (NSString *)locationAuthorizationString {
    return [self.locationManager mme_authorizationStatusString];
}

- (CLAuthorizationStatus)locationAuthorization {
    return [self.locationManager mme_authorizationStatus];
}

- (BOOL)isReducedAccuracy {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    if (@available(iOS 14.0, *)) {
        CLAccuracyAuthorization status = [self.locationManager mme_accuracyStatus];
        return status == CLAccuracyAuthorizationReducedAccuracy;
    } else {
        return NO;
    }
#else
    return NO;
#endif
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (NSString *)accuracyAuthorizationString {
    if (@available(iOS 14.0, *)) {
        return [self.locationManager mme_accuracyAutorizationString];
    } else {
        return @"";
    }
}
#endif

- (void)setLocationManager:(CLLocationManager *)locationManager {
    if (locationManager == nil) {
        _locationManager = locationManager;
    } else {
        id<CLLocationManagerDelegate> delegate = _locationManager.delegate;
        _locationManager.delegate = nil;
        _locationManager = locationManager;
        _locationManager.delegate = delegate;
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
    
    CLAuthorizationStatus authorizationStatus = [self.locationManager mme_authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse && self.hostAppHasBackgroundCapability) {
        if (@available(iOS 9.0, *)) {
            self.locationManager.allowsBackgroundLocationUpdates = self.isMetricsEnabledForInUsePermissions;
        }
    }
}

#pragma mark - Utilities

- (void)configurePassiveLocationManager {
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.locationManager.distanceFilter = MMELocationManagerDistanceFilter;
}

- (void)startLocationServices {
    CLAuthorizationStatus authorizationStatus = [self.locationManager mme_authorizationStatus];
    
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
    CLCircularRegion *region = [CLCircularRegion.alloc
        initWithCenter:location.coordinate
        radius:NSUserDefaults.mme_configuration.mme_backgroundGeofence
        identifier:MMELocationManagerRegionIdentifier];
    region.notifyOnEntry = NO;
    region.notifyOnExit = YES;
    [self.locationManager startMonitoringForRegion:region];
}

#pragma mark - CLLocationManagerDelegate

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 140000
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}
#else
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    CLAuthorizationStatus status = [manager mme_authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}
#endif

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
    [[MMEMetricsManager sharedManager] updateCoordinate:location.coordinate];
    
    // Fix: https://github.com/mapbox/mapbox-events-ios/issues/148
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
    [MMEMetricsManager.sharedManager incrementAppWakeUpCount];
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
