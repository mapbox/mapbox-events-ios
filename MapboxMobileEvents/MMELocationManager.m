#import "MMETypes.h"
#import "MMELocationManager.h"
#import "MMEDependencyManager.h"
#import "MMEEventsConfiguration.h"
#import "MMEMetricsManager.h"
#import <CoreLocation/CoreLocation.h>
#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#endif

static const NSTimeInterval MMELocationManagerHibernationTimeout = 300.0;
static const NSTimeInterval MMELocationManagerHibernationPollInterval = 5.0;

const CLLocationDistance MMELocationManagerDistanceFilter = 5.0;
const CLLocationDistance MMERadiusAccuracyMax = 300.0;

NSString * const MMELocationManagerRegionIdentifier = @"MMELocationManagerRegionIdentifier.fence.center";

@interface MMELocationManager () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, getter=isUpdatingLocation, readwrite) BOOL updatingLocation;
@property (nonatomic) NSDate *backgroundLocationServiceTimeoutAllowedDate;
@property (nonatomic) NSTimer *backgroundLocationServiceTimeoutTimer;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;
@property (nonatomic) MMEEventsConfiguration *configuration;

@end

@implementation MMELocationManager

- (void)dealloc {
    _locationManager.delegate = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
        _hostAppHasBackgroundCapability = [backgroundModes containsObject:@"location"];
        _configuration = [MMEEventsConfiguration configuration];
    }
    return self;
}

- (void)reconfigure:(MMEEventsConfiguration *)configuration {
    self.configuration = configuration;
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
        [self.locationManager stopUpdatingLocation];
#if !TARGET_OS_WATCH && !TARGET_OS_TV && !TARGET_OS_OSX
        [self.locationManager stopMonitoringSignificantLocationChanges];
        [self.locationManager stopMonitoringVisits];
#endif
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
#if !TARGET_OS_WATCH && !TARGET_OS_TV
    for(CLRegion *region in self.locationManager.monitoredRegions) {
        if([region.identifier isEqualToString:MMELocationManagerRegionIdentifier]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
#endif
}

- (void)setMetricsEnabledForInUsePermissions:(BOOL)metricsEnabledForInUsePermissions {
    _metricsEnabledForInUsePermissions = metricsEnabledForInUsePermissions;
    
#if !TARGET_OS_OSX && !TARGET_OS_TV
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse && self.hostAppHasBackgroundCapability) {
        if (@available(iOS 9.0, *)) {
            self.locationManager.allowsBackgroundLocationUpdates = self.isMetricsEnabledForInUsePermissions;
        }
    }
#endif
}

#pragma mark - Utilities

- (void)configurePassiveLocationManager {
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.locationManager.distanceFilter = MMELocationManagerDistanceFilter;
}

- (void)startLocationServices {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    
    BOOL authorizedAlways = authorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
    
#if TARGET_OS_OSX
    if (authorizedAlways) {
#else
    if (authorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
#endif
        
        // If the host app can run in the background with `always` location permissions then allow background
        // updates and start the significant location change service and background timeout timer
        if (authorizedAlways && self.hostAppHasBackgroundCapability) {
#if !TARGET_OS_WATCH && !TARGET_OS_TV
            [self.locationManager startMonitoringSignificantLocationChanges];
#endif
            [self startBackgroundTimeoutTimer];
#if !TARGET_OS_TV && !TARGET_OS_OSX
            if (@available(iOS 9.0, *)) {
                self.locationManager.allowsBackgroundLocationUpdates = YES;
            }
#endif
        }
        
        // If authorization status is when in use specifically, allow background location updates based on
        // if the library is configured to do so. Don't worry about significant location change and the
        // background timer (just above) since all use cases for background collection with in use only
        // permissions involve navigation where a user would want and expect the app to be running / navigating
        // even if it is not in the foreground
#if !TARGET_OS_TV && !TARGET_OS_OSX
        if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse && self.hostAppHasBackgroundCapability) {
            if (@available(iOS 9.0, *)) {
                self.locationManager.allowsBackgroundLocationUpdates = self.isMetricsEnabledForInUsePermissions;
            }
        }
#endif

#if !TARGET_OS_WATCH && !TARGET_OS_TV && !TARGET_OS_OSX
        if (authorizedAlways) {
            [self.locationManager startMonitoringVisits];
        }
#endif

#if !TARGET_OS_TV
        [self.locationManager startUpdatingLocation];
#endif
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

#if !TARGET_OS_WATCH && !TARGET_OS_OSX
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive ||
        UIApplication.sharedApplication.applicationState == UIApplicationStateInactive ) {
        [self startBackgroundTimeoutTimer];
        return;
    }
#endif
    
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
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:self.configuration.locationManagerHibernationRadius identifier:MMELocationManagerRegionIdentifier];
    region.notifyOnEntry = NO;
    region.notifyOnExit = YES;
#if !TARGET_OS_WATCH && !TARGET_OS_TV
    [self.locationManager startMonitoringForRegion:region];
#endif
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
#if TARGET_OS_OSX
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
#else
    if (status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse) {
#endif
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)locationManager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
#if !TARGET_OS_TV
    if (location.speed > 0.0) {
        [self startBackgroundTimeoutTimer];
    }
#endif

#if !TARGET_OS_WATCH && !TARGET_OS_TV && !TARGET_OS_OSX
    if ([self.locationManager.monitoredRegions anyObject] == nil || location.horizontalAccuracy < MMERadiusAccuracyMax) {
        [self establishRegionMonitoringForLocation:location];
    }
#endif

    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [self.delegate locationManager:self didUpdateLocations:locations];
    }
    [[MMEMetricsManager sharedManager] updateCoordinate:location.coordinate];
}

#if !TARGET_OS_WATCH && !TARGET_OS_TV && !TARGET_OS_OSX
- (void)locationManager:(CLLocationManager *)locationManager didExitRegion:(CLRegion *)region {
    [self startBackgroundTimeoutTimer];
    [self.locationManager startUpdatingLocation];
    [[MMEMetricsManager sharedManager] incrementAppWakeUpCount];
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
#endif

@end

