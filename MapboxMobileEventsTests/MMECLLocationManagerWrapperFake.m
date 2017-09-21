#import "MMECLLocationManagerWrapperFake.h"

@implementation MMECLLocationManagerWrapperFake

@synthesize allowsBackgroundLocationUpdates;
@synthesize desiredAccuracy;
@synthesize distanceFilter;
@synthesize monitoredRegions;
@synthesize hostAppHasBackgroundCapability;

- (CLAuthorizationStatus)authorizationStatus {
    return self.stub_authorizationStatus;
}

- (void)startUpdatingLocation {
    [self store:_cmd args:nil];
}

- (void)stopUpdatingLocation {
    [self store:_cmd args:nil];
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
