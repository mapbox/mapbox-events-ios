#import <XCTest/XCTest.h>

#import "MMELocationManager.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "MMEMetricsManager.h"
#import "MMELogger.h"
#import "MMEMockEventConfig.h"
#import "NSURL+Files.h"
#import "LocationManagerCallCounter.h"
#import "MMEBundleInfoFake.h"
#import "LocationManagerCallCounter.h"
#import "MMEUIApplicationWrapperFake.h"

@interface MMELocationManager (Tests)

@property (nonatomic, strong) NSDate *backgroundLocationServiceTimeoutAllowedDate;
@property (nonatomic, strong) NSTimer *backgroundLocationServiceTimeoutTimer;

- (void)timeoutAllowedCheck;

@end

@interface MMELocationManagerTests : XCTestCase <MMELocationManagerDelegate>

@property (nonatomic) CLLocationManager *coreLocationManager;
@property (nonatomic) MMELocationManager *mmeLocationManager;

// Delegate CallCounts
@property (nonatomic, assign) NSUInteger locationManagerDidStartLocationUpdatesCallCount;
@property (nonatomic, assign) NSUInteger locationManagerDidStopLocationUpdatesCallCount;
@property (nonatomic, assign) NSUInteger locationManagerBackgroundLocationUpdatesDidTimeoutCallCount;
@property (nonatomic, assign) NSUInteger locationManagerVisitIsReceivedCallCount;
@property (nonatomic, assign) NSUInteger locationManagerDidUpdateLocationsCallCount;
@property (nonatomic, assign) NSUInteger locationManagerDidPauseLocationUpdatesCallCount;

@end

@interface MMELocationManager (Spec) <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@end

@interface MockBundle: NSBundle


@end

@implementation MMELocationManagerTests

// MARK: - Lifecycle

- (void)setUp {

    self.coreLocationManager = [[CLLocationManager alloc] init];
    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    self.mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config locationManager:LocationManagerCallCounter.new];
    self.mmeLocationManager.delegate = self;

    self.locationManagerDidStartLocationUpdatesCallCount = 0;
    self.locationManagerDidStopLocationUpdatesCallCount = 0;
    self.locationManagerBackgroundLocationUpdatesDidTimeoutCallCount = 0;
    self.locationManagerVisitIsReceivedCallCount = 0;
    self.locationManagerDidUpdateLocationsCallCount = 0;
}

- (void)tearDown {
}

// MARK: - MMELocationManagerDelegate Callback Counting

- (void)locationManagerDidStartLocationUpdates:(MMELocationManager *)locationManager {
    self.locationManagerDidStartLocationUpdatesCallCount += 1;
}

- (void)locationManager:(MMELocationManager *)locationManager didUpdateLocations:(NSArray *)locations {
    self.locationManagerDidUpdateLocationsCallCount += 1;
}

- (void)locationManagerDidStopLocationUpdates:(MMELocationManager *)locationManager {
    self.locationManagerDidStopLocationUpdatesCallCount += 1;
}

- (void)locationManagerBackgroundLocationUpdatesDidTimeout:(MMELocationManager *)locationManager {
    self.locationManagerBackgroundLocationUpdatesDidTimeoutCallCount += 1;
}

- (void)locationManager:(MMELocationManager *)locationManager didVisit:(CLVisit *)visit {
    self.locationManagerVisitIsReceivedCallCount += 1;
}

- (void)locationManagerBackgroundLocationUpdatesDidAutomaticallyPause:(MMELocationManager *)locationManager {
    self.locationManagerDidPauseLocationUpdatesCallCount += 1;
}

-(void)testInitWithConfig {
    MMELocationManager *manager = [[MMELocationManager alloc] initWithConfig:[[MMEMockEventConfig alloc] init]];
    XCTAssertTrue([manager.locationManager isKindOfClass:CLLocationManager.class]);
}

-(void)testDesignatedInitializer {
    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterWhenInUse alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];
    XCTAssertEqual(mmeLocationManager.locationManager, counter);
}

// MARK: - CLLocationManager Delegate Method Handling

- (void)testLocationManagerStartsMonitoringRegions {
    CLLocation *movingLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)
                                                               altitude:0
                                                     horizontalAccuracy:0
                                                       verticalAccuracy:0
                                                                 course:0
                                                                  speed:100.0
                                                              timestamp:[NSDate date]];
    
    [self.mmeLocationManager locationManager:self.coreLocationManager didUpdateLocations:@[movingLocation]];

    // Expect Location Change to trigger change to monitored regions
    XCTAssert(self.coreLocationManager.monitoredRegions > 0);
}



// MARK: - MetricsEnabledForInUsePermissions Tests

// MetricsEnabledForInUsePermissions when the host application has background capability
- (void)testMetricsEnabledForInUsePermissionsWhenBackgroundEnabled {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterWhenInUse alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];

    [mmeLocationManager startUpdatingLocation];

    // Start triggers first call
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 1);

    // Manually Set to true
    mmeLocationManager.metricsEnabledForInUsePermissions = YES;
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 2);
    XCTAssertEqualObjects(counter.setAllowsBackgroundLocationUpdatesCallSequence.lastObject, @YES);

    // Manually Set to false
    mmeLocationManager.metricsEnabledForInUsePermissions = NO;
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 3);
    XCTAssertEqualObjects(counter.setAllowsBackgroundLocationUpdatesCallSequence.lastObject, @NO);
}

// MetricsEnabledForInUsePermissions when the host application does NOT have background capability
- (void)testMetricsEnabledForInUsePermissionsWhenBackgroundDisabled {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterWhenInUse alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];

    [mmeLocationManager startUpdatingLocation];
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 0);

    // Manually Set to true
    mmeLocationManager.metricsEnabledForInUsePermissions = YES;
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 0);
}

// MARK: - Start Updating Location Tests

- (void)testStartLocationWithDeniedPermissions {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterDenied alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];

    [mmeLocationManager startUpdatingLocation];

    // When the host app has is denied location permissions then the location manager should NOT consider itself to be updating
    XCTAssertFalse(mmeLocationManager.isUpdatingLocation);
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 0);
}

- (void)testStartLocationWithAlwaysPermissions {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];
    mmeLocationManager.delegate = self;
    XCTAssertNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);

    [mmeLocationManager startUpdatingLocation];

    // MME Location Manager Should be the delegate
    XCTAssertEqual(counter.delegate, mmeLocationManager);
    XCTAssertEqual(mmeLocationManager.delegate, self);

    // Sets the desired accuracy correctly
    XCTAssertEqual(counter.desiredAccuracy, kCLLocationAccuracyThreeKilometers);

    // Sets the distance filter correctly
    XCTAssertEqual(counter.distanceFilter, MMELocationManagerDistanceFilter);

    // Calls the location manager wrapper's startMonitoringSignificantLocationChanges method
    XCTAssertEqual(counter.startMonitoringSignificantLocationChangesCallCount, 1);

    // Starts the background timer
    XCTAssertNotNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);

    // Starts Updating Location
    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);

    // Tells the location manager wrapper to allow background location updates

    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 1);
    XCTAssertEqualObjects(counter.setAllowsBackgroundLocationUpdatesCallSequence.lastObject, @YES);

    // Tells the location manager wrapper to start updating location
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 1);

    // Tells the location manager to notify the delegate that it started location updates
    XCTAssertEqual(self.locationManagerDidStartLocationUpdatesCallCount, 1);
}

- (void)testStartLocationWithAlwaysPermissionsWithoutBackgroundCapability {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];
    mmeLocationManager.delegate = self;
    [mmeLocationManager startUpdatingLocation];

    // MME Location Manager Should be the delegate
    XCTAssertEqual(counter.delegate, mmeLocationManager);
    XCTAssertEqual(mmeLocationManager.delegate, self);

    // Should not tell location manager to startMonitoringSignificantLocationChanges
    XCTAssertEqual(counter.startMonitoringSignificantLocationChangesCallCount, 0);

    // The background timer should not be started
    XCTAssertNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);

    // Should not tell location manager to allowsBackgroundLocationUpdates
    XCTAssertFalse(counter.allowsBackgroundLocationUpdates);

    // Should not have received setAllowsBackgroundLocationUpdates
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 0);

    // Tells the location manager wrapper to start updating location
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 1);

    // location manager considers itself to be updating location
    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);

    // Tells the location manager to notify the delegate that it started location updates
    XCTAssertEqual(self.locationManagerDidStartLocationUpdatesCallCount, 1);

    // When authorization status changes to when in use then the location manager should consider itself to be updating
    [mmeLocationManager locationManager:counter didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse];
    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);
}

- (void)testStartLocationWithWhenInUsePermissionsWithoutBackgroundCapability {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterWhenInUse alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];
    mmeLocationManager.delegate = self;

    [mmeLocationManager startUpdatingLocation];

    // MME Location Manager Should be the delegate
    XCTAssertEqual(counter.delegate, mmeLocationManager);
    XCTAssertEqual(mmeLocationManager.delegate, self);

    // Should not tell location manager to startMonitoringSignificantLocationChanges
    XCTAssertEqual(counter.startMonitoringSignificantLocationChangesCallCount, 0);

    // The background timer should not be started
    XCTAssertNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);

    // Should not tell location manager to allowsBackgroundLocationUpdates
    XCTAssertFalse(counter.allowsBackgroundLocationUpdates);

    // Tells the location manager wrapper to allow background location updates
    XCTAssertEqual(counter.setAllowsBackgroundLocationUpdatesCallSequence.count, 0);

    // Tells the location manager wrapper to start updating location
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 1);

    // location manager considers itself to be updating location
    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);

    // Tells the location manager to notify the delegate that it started location updates
    XCTAssertEqual(self.locationManagerDidStartLocationUpdatesCallCount, 1);

    // When authorization status changes to AuthorizedAlways then the location manager should consider itself to be updating
    [mmeLocationManager locationManager:counter didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);
}

-(void)testStartUpdatingLocationWithLocationDisabled {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterDenied alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];
    mmeLocationManager.delegate = self;
    [mmeLocationManager startUpdatingLocation];

    XCTAssertFalse(mmeLocationManager.isUpdatingLocation);
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 0);
}

/*
 - (void)startUpdatingLocation {
 if (![self.locationManager.class locationServicesEnabled]) {
 return;
 }
 if ([self isUpdatingLocation]) {
 return;
 }

 [self configurePassiveLocationManager];
 [self startLocationServices];
 }
 */

// MARK: - StopUpdatingLocation Tests

-(void)testStopUpdatingLocation {

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterWhenInUse alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle];
    mmeLocationManager.delegate = self;

    [mmeLocationManager startUpdatingLocation];
    [mmeLocationManager stopUpdatingLocation];

    // Verify Not Running
    XCTAssertFalse(mmeLocationManager.isUpdatingLocation);
    XCTAssertNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);


    // Verify Delegate Callbacks
    XCTAssertEqual(self.locationManagerDidStartLocationUpdatesCallCount, 1);
    XCTAssertEqual(self.locationManagerDidStopLocationUpdatesCallCount, 1);
}

// MARK: - Time Allowed Tests

-(void)testTimeoutAllowedInBackground {

    // When the host app is in the background, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateBackground;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    mmeLocationManager.delegate = self;
    [mmeLocationManager startUpdatingLocation];

    // When Timeout Set to now is called
    mmeLocationManager.backgroundLocationServiceTimeoutAllowedDate = NSDate.new;
    [mmeLocationManager timeoutAllowedCheck];

    // Tells location manager to stop updating location
    XCTAssertFalse(mmeLocationManager.isUpdatingLocation);
    XCTAssertEqual(self.locationManagerDidStopLocationUpdatesCallCount, 1);

    // Should reset timeout
    XCTAssertNil(mmeLocationManager.backgroundLocationServiceTimeoutAllowedDate);

    // tells location manager's delegate that location updates timed out"
    XCTAssertEqual(self.locationManagerBackgroundLocationUpdatesDidTimeoutCallCount, 1);
}

-(void)testTimeoutAllowedInForeground {

    // When the host app is in the foreground, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    mmeLocationManager.delegate = self;
    [mmeLocationManager startUpdatingLocation];

    // TODO: Add tests

    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);
    [mmeLocationManager timeoutAllowedCheck];

    // Then location manager should have not received stopUpdatingLocation"
    XCTAssertEqual(self.locationManagerDidStopLocationUpdatesCallCount, 0);

    // Then the location manager's backgroundLocationServiceTimeoutTimer should not be nil"
    XCTAssertNotNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);
}

-(void)testTimeoutAllowedInForegroundNotUpdating {

    // When the host app is in the foreground, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    mmeLocationManager.delegate = self;

    // When timeoutAllowedCheck and the location manager is NOT updating location
    XCTAssertFalse(mmeLocationManager.isUpdatingLocation);
    [mmeLocationManager timeoutAllowedCheck];

    // Then location manager should have not received stopUpdatingLocation"
    XCTAssertEqual(self.locationManagerDidStopLocationUpdatesCallCount, 0);

    // Then the location manager's backgroundLocationServiceTimeoutTimer should not be nil"
    XCTAssertNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);
}

// MARK: - CLLocationManagerDelegate Interactions - Ensure Delegate Methods Are correctly Passed through to MMELocationManagerDelegate

-(void)testDidChangeAuthorizationStatusAuthorizedAlways {
    // When the host app is in the foreground, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    [mmeLocationManager locationManager:counter didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 1);
}

-(void)testDidChangeAuthorizationStatusWhenInUse {
    // When the host app is in the foreground, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterWhenInUse alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    [mmeLocationManager locationManager:counter didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 1);
}

-(void)testDidChangeAuthorizationStatusDenied {
    // When the host app is in the foreground, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterDenied alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    [mmeLocationManager locationManager:counter didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 0);
}

- (void)testDidChangeAuthorizationStatusRestricted {
    // When the host app is in the foreground, has always location permissions, and after startUpdatingLocation has been called
    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounter alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    [mmeLocationManager locationManager:counter didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    XCTAssertEqual(counter.startUpdatingLocationCallCount, 0);
}

-(void)testStationaryLocationIsReceived {
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)
                                                         altitude:0
                                               horizontalAccuracy:0
                                                 verticalAccuracy:0
                                                           course:0
                                                            speed:0.0
                                                        timestamp:[NSDate date]];
    [self.mmeLocationManager locationManager:self.coreLocationManager didUpdateLocations:@[location]];

    // Should notify delegate
    XCTAssertEqual(self.locationManagerDidUpdateLocationsCallCount, 1);

    // Should not start timer
    XCTAssertNil(self.mmeLocationManager.backgroundLocationServiceTimeoutTimer);
}

-(void)testMovingLocationUpdatesReceived {

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)
                                                         altitude:0
                                               horizontalAccuracy:0
                                                 verticalAccuracy:0
                                                           course:0
                                                            speed:100.0
                                                        timestamp:[NSDate date]];

    [self.mmeLocationManager locationManager:self.coreLocationManager didUpdateLocations:@[location]];

    // When a moving location is received, should start the timer
    XCTAssertNotNil(self.mmeLocationManager.backgroundLocationServiceTimeoutTimer);
}

-(void)testDelegateCallVisitIsReceived {
    CLVisit *visit = [[CLVisit alloc] init];
    [self.mmeLocationManager locationManager:self.coreLocationManager didVisit:visit];
    XCTAssertEqual(self.locationManagerVisitIsReceivedCallCount, 1);
}

-(void)testDelegateDidExitRegion {

    MMEUIApplicationWrapperFake *application = [[MMEUIApplicationWrapperFake alloc] init];
    application.applicationState = UIApplicationStateActive;

    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    MMEBundleInfoFake *bundle = [MMEBundleInfoFake bundleWithFakeInfo:@{
        @"UIBackgroundModes": @[
                @"location"
        ]
    }];
    LocationManagerCallCounter *counter = [[LocationManagerCallCounterAuthorizedAlways alloc] init];
    MMELocationManager *mmeLocationManager = [[MMELocationManager alloc] initWithConfig:config
                                                                        locationManager:counter
                                                                                 bundle:bundle
                                                                            application:application];

    // When Existing a region
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0, 0)
                                      radius:300
                                  identifier:@"MMELocationManagerRegionIdentifier.fence.center"];

    mmeLocationManager.delegate = self;
    [mmeLocationManager startUpdatingLocation];

    [mmeLocationManager locationManager:self.coreLocationManager didExitRegion:region];

    // Timer Should be started
    XCTAssertNotNil(mmeLocationManager.backgroundLocationServiceTimeoutTimer);

    // Should be updatingLocation
    XCTAssertTrue(mmeLocationManager.isUpdatingLocation);

}

-(void)testLocationManagerDidPauseLocationUpdates {
    self.mmeLocationManager.delegate = self;
    [self.mmeLocationManager locationManagerDidPauseLocationUpdates:self.coreLocationManager];
    XCTAssertEqual(self.locationManagerDidPauseLocationUpdatesCallCount, 1);


}

// MARK: - Listeners (Registered Callback Closures)

-(void)testOnDidExitRegionListener {

    __block int onDidExitRegionCount = 0;
    [self.mmeLocationManager registerOnDidExitRegion:^(CLRegion *region) {
        onDidExitRegionCount += 1;
    }];

    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0, 0)
                                                                 radius:300
                                                             identifier:@"MMELocationManagerRegionIdentifier.fence.center"];

    [self.mmeLocationManager locationManager:self.coreLocationManager didExitRegion:region];

    XCTAssertEqual(onDidExitRegionCount, 1);

}

-(void)testOnDidUpdateCoordinateCalls {

    __block int onDidUpdateLocationsCallCount = 0;
    [self.mmeLocationManager registerOnDidUpdateCoordinate:^(CLLocationCoordinate2D coordinate) {
        onDidUpdateLocationsCallCount += 1;
    }];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    [self.mmeLocationManager locationManager:self.coreLocationManager didUpdateLocations:@[location]];
    XCTAssertEqual(onDidUpdateLocationsCallCount, 1);
}

@end
