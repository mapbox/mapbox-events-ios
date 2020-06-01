#import "LocationManagerCallCounter.h"

@implementation LocationManagerCallCounter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.setAllowsBackgroundLocationUpdatesCallSequence = [NSMutableArray array];
    }
    return self;
}
// MARK: - Initiating Standard Location Updates

- (void)startUpdatingLocation {
    self.startUpdatingLocationCallCount += 1;
    [super startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    self.stopUpdatingLocationCallCount +=1;
    [super stopUpdatingLocation];
}

-(void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates {
    [self.setAllowsBackgroundLocationUpdatesCallSequence addObject:[NSNumber numberWithBool:allowsBackgroundLocationUpdates]];
}

- (void)startMonitoringSignificantLocationChanges {
    self.startMonitoringSignificantLocationChangesCallCount += 1;
    [super startMonitoringSignificantLocationChanges];
}

@end

@implementation LocationManagerCallCounterWhenInUse

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusAuthorizedWhenInUse;
}

@end

@implementation LocationManagerCallCounterAuthorizedAlways

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusAuthorizedAlways;
}

@end

@implementation LocationManagerCallCounterDenied

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusDenied;
}

@end

@implementation LocationManagerCallCounterRestricted

+ (CLAuthorizationStatus)authorizationStatus {
    return kCLAuthorizationStatusRestricted;
}

@end
