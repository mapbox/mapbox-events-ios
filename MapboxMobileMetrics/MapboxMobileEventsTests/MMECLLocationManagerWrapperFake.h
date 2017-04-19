#import <Foundation/Foundation.h>
#import "MMECLLocationManagerWrapper.h"

@interface MMECLLocationManagerWrapperFake : NSObject <MMECLLocationManagerWrapper>

@property (nonatomic, weak) id<MMECLLocationManagerWrapperDelegate> delegate;
@property (nonatomic, copy, readwrite) NSSet<__kindof CLRegion *> *monitoredRegions;
@property (nonatomic) CLRegion *startMonitoringRegion;
@property (nonatomic) CLRegion *stopMonitoringRegion;

// Stubs

@property (nonatomic) CLAuthorizationStatus stub_authorizationStatus;
@property (nonatomic) NSSet<__kindof CLRegion *> *stub_monitoredRegions;

// Dispatch validation

@property (nonatomic) BOOL received_startMonitoringSignificantLocationChanges;
@property (nonatomic) BOOL received_stopMonitoringSignificantLocationChanges;
@property (nonatomic) BOOL received_startUpdatingLocation;
@property (nonatomic) BOOL received_stopUpdatingLocation;

- (BOOL)received_stopMonitoringForRegionWithRegion:(CLRegion *)region;
- (BOOL)received_startMonitoringForRegionWithRegion:(CLRegion *)region;

@end
