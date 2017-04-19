#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>

#import "MMELocationManager.h"
#import "MMECLLocationManagerWrapper.h"

#import "MMETestStub.h"
#import "MMECLLocationManagerWrapperFake.h"
#import "MMEUIApplicationWrapperFake.h"

@class MMELocationManagerDelegateStub;

@interface MMELocationManagerTests : XCTestCase

@property (nonatomic) MMELocationManager *locationManager;
@property (nonatomic) MMEUIApplicationWrapperFake *application;
@property (nonatomic) MMECLLocationManagerWrapperFake *locationManagerWrapper;
@property (nonatomic) MMELocationManagerDelegateStub *delegateStub;

@end

@interface MMELocationManager (Tests)

@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) id<MMECLLocationManagerWrapper> locationManager;
@property (nonatomic) BOOL hostAppHasBackgroundCapability;
@property (nonatomic, getter=isUpdatingLocation, readwrite) BOOL updatingLocation;
@property (nonatomic) NSTimer *backgroundLocationServiceTimeoutTimer;
@property (nonatomic) NSDate *backgroundLocationServiceTimeoutAllowedDate;

- (void)timeoutAllowedCheck;

@end

@interface MMELocationManagerDelegateStub : MMETestStub <MMELocationManagerDelegate>

@end

@implementation MMELocationManagerDelegateStub

- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    [self store:_cmd args:@[locationManager]];
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    [self store:_cmd args:@[locationManager]];
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    [self store:_cmd args:@[locationManager]];
}

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    [self store:_cmd args:@[locations]];
}

@end

@implementation MMELocationManagerTests

- (void)setUp {
    [super setUp];

    self.locationManager = [[MMELocationManager alloc] init];
    self.application = [[MMEUIApplicationWrapperFake alloc] init];
    self.locationManager.application = self.application;
    self.locationManagerWrapper = [[MMECLLocationManagerWrapperFake alloc] init];
    self.locationManager.locationManager = self.locationManagerWrapper;
    self.delegateStub = [[MMELocationManagerDelegateStub alloc] init];
    self.locationManager.delegate = self.delegateStub;
}

- (void)testStartUpdatingLocationWhenHostAppHasBackgroundCapabilityAndAlwaysPermissions {
    self.locationManager.hostAppHasBackgroundCapability = YES;
    self.locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedAlways;

    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"background timer should not be started");

    [self.locationManager startUpdatingLocation];

    XCTAssert(self.locationManagerWrapper.delegate == self.locationManager, @"MME location manager should set itself as the delegate of the location manager wrapper");
    XCTAssert(self.locationManagerWrapper.desiredAccuracy == kCLLocationAccuracyThreeKilometers, @"MME location manager should correctly set the location manager wrapper's desired accuracy");
    XCTAssert(self.locationManagerWrapper.distanceFilter == MMELocationManagerDistanceFilter, @"MME location manager should correctly set the location manager wrapper's distance filter");
    XCTAssert([self.locationManagerWrapper received:@selector(startMonitoringSignificantLocationChanges) withArguments:nil], @"CL location manager should have been told to start monitoring significant location changes");
    XCTAssertNotNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"MME location manager should start its background timer");
    XCTAssert(self.locationManager.isUpdatingLocation, @"MME locationManager should consider itself to be updating location");
    XCTAssert(self.locationManagerWrapper.allowsBackgroundLocationUpdates, @"CL location manager should have been told to allow background location updates");

    XCTAssert([self.locationManagerWrapper received:@selector(startUpdatingLocation) withArguments:nil], @"CL location manager should have been told to start updating location");
    XCTAssert([self.delegateStub received:@selector(locationManagerDidStartLocationUpdates:) withArguments:@[self.locationManager]], @"MME location manager should notify its delegate that it started location updates");
}

- (void)testStartUpdatingLocationWhenHostAppHasNoBackgroundCapabilityAndAlwaysPermissions {
    self.locationManager.hostAppHasBackgroundCapability = NO;
    self.locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedAlways;

    [self.locationManager startUpdatingLocation];
    [self assertThatLocationManagerBehavesCorrectlyWhenAuthorizedForWhenInUseOnlyOrWhenItHasNoBackgroundCapability];
}

- (void)testStartUpdatingLocationWhenHostAppHasWhenInUsePermissions {
    self.locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [self.locationManager startUpdatingLocation];
    [self assertThatLocationManagerBehavesCorrectlyWhenAuthorizedForWhenInUseOnlyOrWhenItHasNoBackgroundCapability];
}

- (void)testStopUpdatingLocation {
    self.locationManager.updatingLocation = YES;
    [self.locationManager stopUpdatingLocation];
    XCTAssert([self.locationManagerWrapper received:@selector(stopUpdatingLocation) withArguments:nil], @"CL location manager should have been told to stop updating location");
    XCTAssert([self.locationManagerWrapper received:@selector(stopMonitoringSignificantLocationChanges) withArguments:nil], @"CL location manager should have been told to stop monitoring for significant location changes");
    XCTAssertFalse(self.locationManager.isUpdatingLocation, @"MME locationManager should not consider itself to be updating location");
    XCTAssert([self.delegateStub received:@selector(locationManagerDidStopLocationUpdates:) withArguments:@[self.locationManager]], @"MME location manager should tell its delegate that location updates were stopped");
}

- (void)testStopUpdatingLocationWhenThereAreMonitoredRegions {
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0, 0) radius:10 identifier:MMELocationManagerRegionIdentifier];
    self.locationManagerWrapper.monitoredRegions = [NSSet setWithObject:region];
    self.locationManager.updatingLocation = YES;
    [self.locationManager stopUpdatingLocation];

    XCTAssert([self.locationManagerWrapper received:@selector(stopMonitoringForRegion:) withArguments:@[region]], @"It should tell the CL location manager to start monitoring for region");
}

- (void)testTimeoutAfterExpiryInBackground {
    self.locationManager.updatingLocation = YES;
    self.locationManager.backgroundLocationServiceTimeoutAllowedDate = [NSDate date];
    self.application.applicationState = UIApplicationStateBackground;

    [self.locationManager timeoutAllowedCheck];

    XCTAssert([self.locationManagerWrapper received:@selector(stopUpdatingLocation) withArguments:nil], @"CL location manager should have been told to stop updating location");
    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutAllowedDate, @"timeout should be reset");
    XCTAssert([self.delegateStub received:@selector(locationManagerBackgroundLocationUpdatesDidTimeout:) withArguments:@[self.locationManager]], @"MME location manager should tell its delegate that location updates timed out");
}

- (void)testTimeoutBeforeExpiryInBackground {
    self.locationManager.updatingLocation = YES;
    self.locationManager.backgroundLocationServiceTimeoutAllowedDate = [NSDate distantFuture];
    self.application.applicationState = UIApplicationStateBackground;

    [self.locationManager timeoutAllowedCheck];

    XCTAssertFalse([self.locationManagerWrapper received:@selector(stopUpdatingLocation) withArguments:nil], @"CL location manager should not have been told to stop updating location");
    XCTAssertNotNil(self.locationManager.backgroundLocationServiceTimeoutAllowedDate, @"timeout should not be reset");
    XCTAssertFalse([self.delegateStub received:@selector(locationManagerBackgroundLocationUpdatesDidTimeout:) withArguments:nil], @"MME location manager should tell its delegate that location updates timed out");
}

- (void)testTimeoutInForeground {
    self.locationManager.updatingLocation = YES;
    self.locationManager.backgroundLocationServiceTimeoutTimer = nil;
    [self.locationManager timeoutAllowedCheck];

    XCTAssertNotNil(self.locationManager.backgroundLocationServiceTimeoutTimer);
    XCTAssertFalse([self.locationManagerWrapper received:@selector(stopUpdatingLocation) withArguments:nil], @"CL location manager should not have been told to stop updating location");
}

- (void)testTimeoutWhenNotUpdatingLocation {
    self.locationManager.updatingLocation = NO;
    self.locationManager.backgroundLocationServiceTimeoutTimer = nil;
    [self.locationManager timeoutAllowedCheck];

    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutTimer);
    XCTAssertFalse([self.locationManagerWrapper received:@selector(stopUpdatingLocation) withArguments:nil], @"CL location manager should not have been told to stop updating location");
}

- (void)testAsDelegateForLocationManagerWrapperAuthorizationStatusChangeToAlways {
    self.locationManager.hostAppHasBackgroundCapability = YES;
    self.locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedWhenInUse;

    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];

    XCTAssert(self.locationManager.isUpdatingLocation, @"MME locationManager should consider itself to be updating location");
}

- (void)testAsDelegateForLocationManagerWrapperAuthorizationStatusChangeToWhenInUse {
    self.locationManager.hostAppHasBackgroundCapability = YES;
    self.locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedAlways;

    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse];
    XCTAssert(self.locationManager.isUpdatingLocation, @"MME locationManager should consider itself to be updating location");
}

- (void)testAsDelegateForLocationManagerWrapperAuthorizationStatusChangeToDenied {
    self.locationManager.hostAppHasBackgroundCapability = NO;
    self.locationManagerWrapper.stub_authorizationStatus = kCLAuthorizationStatusAuthorizedAlways;

    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didChangeAuthorizationStatus:kCLAuthorizationStatusDenied];
    XCTAssertFalse(self.locationManager.isUpdatingLocation, @"MME locationManager should not consider itself to be updating location");
}

- (void)testAsDelegateForLocationManagerWrapperDidUpdateLocations {
    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutTimer);

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:1.0 timestamp:[NSDate date]];
    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[location]];

    XCTAssertNotNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"It should start the timer");

    CLRegion *expectedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0, 0) radius:MMELocationManagerHibernationRadius identifier:MMELocationManagerRegionIdentifier];
    expectedRegion.notifyOnEntry = NO;
    expectedRegion.notifyOnExit = YES;

    XCTAssert([self.locationManagerWrapper received:@selector(startMonitoringForRegion:) withArguments:@[expectedRegion]], @"It should tell the CL location manager to start monitoring for region");
}

- (void)testAsDelegateForLocationManagerWrapperDidUpdateLocationsLocationSpeeds {
    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"Timer should be stopped");

    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[[self stationaryLocation]]];
    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"Timer should be stopped");

    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[[self movingLocation]]];
    XCTAssertNotNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"It should start the timer");
}

- (void)testAsDelegateForLocationManagerWrapperDidUpdateLocationsRegionMonitoring {
    // When there is already a monitored region and an inaccurate location is received
    self.locationManagerWrapper.monitoredRegions = [NSSet setWithObject:[[CLCircularRegion alloc] init]];
    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[[self inaccurateLocation]]];
    XCTAssertFalse([self.locationManagerWrapper received:@selector(startMonitoringForRegion:) withArguments:nil], @"It should tell the CL location manager to start monitoring for region");

    // When there are no monitored regions and an accurate location is received
    self.locationManagerWrapper.monitoredRegions = [NSSet set];
    CLRegion *expectedRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0, 0) radius:MMELocationManagerHibernationRadius identifier:MMELocationManagerRegionIdentifier];
    expectedRegion.notifyOnEntry = NO;
    expectedRegion.notifyOnExit = YES;
    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[[self accurateLocation]]];
    XCTAssert([self.locationManagerWrapper received:@selector(startMonitoringForRegion:) withArguments:@[expectedRegion]], @"It should tell the CL location manager to start monitoring for region");

    // When there are no monitored regions and an inaccurate location is received
    self.locationManagerWrapper.monitoredRegions = [NSSet set];
    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[[self inaccurateLocation]]];
    XCTAssert([self.locationManagerWrapper received:@selector(startMonitoringForRegion:) withArguments:@[expectedRegion]], @"It should tell the CL location manager to start monitoring for region");
}

- (void)testAsDelegateForLocationManagerWrapperDidUpdateLocationsRegionMonitoringDelegation {
    CLLocation *location = [self accurateLocation];
    [self.locationManager locationManagerWrapper:self.locationManagerWrapper didUpdateLocations:@[location]];
    XCTAssertTrue([self.delegateStub received:@selector(locationManager:didUpdateLocations:) withArguments:@[@[location]]], @"It should tell its delegate");
}

#pragma mark - Common

- (void)assertThatLocationManagerBehavesCorrectlyWhenAuthorizedForWhenInUseOnlyOrWhenItHasNoBackgroundCapability {
    XCTAssertFalse([self.locationManagerWrapper received:@selector(startMonitoringSignificantLocationChanges) withArguments:nil], @"CL location manager should not have been told to start monitoring significant location changes");
    XCTAssertNil(self.locationManager.backgroundLocationServiceTimeoutTimer, @"background timer should not be started");
    XCTAssertFalse(self.locationManagerWrapper.allowsBackgroundLocationUpdates, @"CL location manager should not have been told to allow background location updates");
    XCTAssert([self.locationManagerWrapper received:@selector(startUpdatingLocation) withArguments:nil], @"CL location manager should have been told to start updating location");
    XCTAssert(self.locationManager.isUpdatingLocation, @"MME locationManager should consider itself to be updating location");
    XCTAssert([self.delegateStub received:@selector(locationManagerDidStartLocationUpdates:) withArguments:@[self.locationManager]], @"MME location manager should notify its delegate that it started location updates");
}

- (CLLocation *)stationaryLocation {
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:0.0 timestamp:[NSDate date]];
}

- (CLLocation *)movingLocation {
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:100.0 timestamp:[NSDate date]];
}

- (CLLocation *)accurateLocation {
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:0.0 timestamp:[NSDate date]];
}

- (CLLocation *)inaccurateLocation {
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:0 horizontalAccuracy:99999 verticalAccuracy:0 course:0 speed:0.0 timestamp:[NSDate date]];
}

@end
