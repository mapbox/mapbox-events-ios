#import "MMELocationManager.h"
#import "MMETestStub.h"

@interface MMELocationManagerFake : MMETestStub <MMELocationManager>

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;
@property (nonatomic, getter=isMetricsEnabledForInUsePermissions) BOOL metricsEnabledForInUsePermissions;
@property (nonatomic, copy, readwrite) NSSet<__kindof CLRegion *> *monitoredRegions;
@property (nonatomic) CLAuthorizationStatus stub_authorizationStatus;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
