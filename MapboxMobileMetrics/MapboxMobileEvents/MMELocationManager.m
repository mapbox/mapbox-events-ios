#import "MMELocationManager.h"
#import "MMECLLocationManagerWrapper.h"

static const NSTimeInterval MMELocationManagerHibernationTimeout = 300.0;
static const NSTimeInterval MMELocationManagerHibernationPollInterval = 5.0;
static const CLLocationDistance MMELocationManagerHibernationRadius = 300.0;
static const CLLocationDistance MMELocationManagerDistanceFilter = 5.0;
static NSString * const MMELocationManagerRegionIdentifier = @"MMELocationManagerRegionIdentifier.fence.center";

@interface MMELocationManager ()

@property (nonatomic) MMECLLocationManagerWrapper *locationManager;
@property (nonatomic) CLLocationManager *standardLocationManager;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;
@property (nonatomic, getter=isUpdatingLocation, readwrite) BOOL updatingLocation;
@property (nonatomic) NSDate *backgroundLocationServiceTimeoutAllowedDate;
@property (nonatomic) NSTimer *backgroundLocationServiceTimeoutTimer;

@end

@implementation MMELocationManager

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
        _hostAppHasBackgroundCapability = [backgroundModes containsObject:@"location"];
        _locationManager = [[MMECLLocationManagerWrapper alloc] init];
    }
    return self;
}

- (void)startUpdatingLocation {
    if ([self isUpdatingLocation]) {
        return;
    }

    [self configurePassiveStandardLocationManager];
    [self startLocationServices];
}

- (void)stopUpdatingLocation {
    if ([self isUpdatingLocation]) {
        [self.standardLocationManager stopUpdatingLocation];
        [self.standardLocationManager stopMonitoringSignificantLocationChanges];
        self.updatingLocation = NO;
        if ([self.delegate respondsToSelector:@selector(locationManagerDidStopLocationUpdates:)]) {
            [self.delegate locationManagerDidStopLocationUpdates:self];
        }
    }
    if(self.standardLocationManager.monitoredRegions.count > 0) {
        for(CLRegion *region in self.standardLocationManager.monitoredRegions) {
            if([region.identifier isEqualToString:MMELocationManagerRegionIdentifier]) {
                [self.standardLocationManager stopMonitoringForRegion:region];
            }
        }
    }
}

#pragma mark - Utilities

- (void)configurePassiveStandardLocationManager {
    if (!self.standardLocationManager) {
        CLLocationManager *standardLocationManager = [[CLLocationManager alloc] init];
        standardLocationManager.delegate = self;
        standardLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        standardLocationManager.distanceFilter = MMELocationManagerDistanceFilter;
        self.standardLocationManager = standardLocationManager;
    }
}

- (void)startLocationServices {
    CLAuthorizationStatus authorizationStatus = [self.locationManager authorizationStatus];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
    BOOL authorizedAlways = authorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
#else
    BOOL authorizedAlways = authorizationStatus == kCLAuthorizationStatusAuthorized;
#endif
    if (authorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // If the host app can run in the background with `always` location permissions then allow background
        // updates and start the significant location change service and background timeout timer
        if (self.hostAppHasBackgroundCapability && authorizedAlways) {
            [self.standardLocationManager startMonitoringSignificantLocationChanges];
            [self startBackgroundTimeoutTimer];
            // On iOS 9 and above also allow background location updates
            if ([self.standardLocationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
                self.standardLocationManager.allowsBackgroundLocationUpdates = YES;
            }
        }

        [self.standardLocationManager startUpdatingLocation];
        self.updatingLocation = YES;
        if ([self.delegate respondsToSelector:@selector(locationManagerDidStartLocationUpdates:)]) {
            [self.delegate locationManagerDidStartLocationUpdates:self];
        }
    }
}

- (void)timeoutAllowedCheck {
    if (self.backgroundLocationServiceTimeoutAllowedDate == nil) {
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive ||
        [UIApplication sharedApplication].applicationState == UIApplicationStateInactive ) {
        [self startBackgroundTimeoutTimer];
        return;
    }

    NSTimeInterval timeIntervalSinceTimeoutAllowed = [[NSDate date] timeIntervalSinceDate:self.backgroundLocationServiceTimeoutAllowedDate];
    if (timeIntervalSinceTimeoutAllowed > 0) {
        [self.standardLocationManager stopUpdatingLocation];
        self.backgroundLocationServiceTimeoutAllowedDate = nil;
        if ([self.delegate respondsToSelector:@selector(locationManagerBackgroundLocationUpdatesDidTimeout:)]) {
            [self.delegate locationManagerBackgroundLocationUpdatesDidTimeout:self];
        }
    }
}

- (void)startBackgroundTimeoutTimer {
    [self.backgroundLocationServiceTimeoutTimer invalidate];
    self.backgroundLocationServiceTimeoutAllowedDate = [[NSDate date] dateByAddingTimeInterval:MMELocationManagerHibernationTimeout];
    self.backgroundLocationServiceTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:MMELocationManagerHibernationPollInterval target:self selector:@selector(timeoutAllowedCheck) userInfo:nil repeats:YES];
}

- (void)establishRegionMonitoringForLocation:(CLLocation *)location {
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:MMELocationManagerHibernationRadius identifier:MMELocationManagerRegionIdentifier];
    region.notifyOnEntry = NO;
    region.notifyOnExit = YES;
    [self.standardLocationManager startMonitoringForRegion:region];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
        case kCLAuthorizationStatusAuthorizedAlways:
#else
        case kCLAuthorizationStatusAuthorized:
#endif
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startUpdatingLocation];
            break;
        default:
            [self stopUpdatingLocation];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    if (location.speed > 0.0) {
        [self startBackgroundTimeoutTimer];
    }
    if (self.standardLocationManager.monitoredRegions.count == 0 || location.horizontalAccuracy < MMELocationManagerHibernationRadius) {
        [self establishRegionMonitoringForLocation:location];
    }
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [self.delegate locationManager:self didUpdateLocations:locations];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self startBackgroundTimeoutTimer];
    [self.standardLocationManager startUpdatingLocation];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if ([self.delegate respondsToSelector:@selector(locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:)]) {
            [self.delegate locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:self];
        }
    }
}

@end
