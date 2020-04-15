#import "MMELocationManagerFake.h"

@implementation MMELocationManagerFake

//@synthesize allowsBackgroundLocationUpdates;
//@synthesize desiredAccuracy;
//@synthesize distanceFilter;
//@synthesize monitoredRegions;

- (void)startUpdatingLocation {
    [self store:_cmd args:nil];
}

- (void)stopUpdatingLocation {
    [self store:_cmd args:nil];
}

- (CLAuthorizationStatus)authorizationStatus {
    return self.stub_authorizationStatus;
}

- (void)startMonitoringSignificantLocationChanges {
    [self store:_cmd args:nil];
}

- (void)stopMonitoringSignificantLocationChanges {
    [self store:_cmd args:nil];
}

- (void)startMonitoringForRegion:(CLRegion *)region {
    [self store:_cmd args:@[region]];
}

- (void)stopMonitoringForRegion:(CLRegion *)region {
    [self store:_cmd args:@[region]];
}

@end
