#import "MMECLLocationManagerWrapperFake.h"

@implementation MMECLLocationManagerWrapperFake

@synthesize allowsBackgroundLocationUpdates;
@synthesize desiredAccuracy;
@synthesize distanceFilter;
@synthesize monitoredRegions;

- (CLAuthorizationStatus)authorizationStatus {
    return self.stub_authorizationStatus;
}

- (void)startUpdatingLocation {
    self.received_startUpdatingLocation = YES;
}

- (void)stopUpdatingLocation {
    self.received_stopUpdatingLocation = YES;
}

- (void)startMonitoringSignificantLocationChanges {
    self.received_startMonitoringSignificantLocationChanges = YES;
}

- (void)stopMonitoringSignificantLocationChanges {
    self.received_stopMonitoringSignificantLocationChanges = YES;
}

- (void)stopMonitoringForRegion:(CLRegion *)region {
    self.stopMonitoringRegion = region;
}

- (BOOL)received_stopMonitoringForRegionWithRegion:(CLRegion *)region {
    return [region isEqual:self.stopMonitoringRegion];
}

@end
