#import <Cedar/Cedar.h>
#import <CoreLocation/CoreLocation.h>

#import "MMELocationManager.h"
#import "MMECLLocationManagerWrapper.h"
#import "MMEDependencyManager.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMECLLocationManagerWrapper (Spec)

@property (nonatomic) CLLocationManager *locationManager;

@end

@interface MMELocationManager (Spec)

@property (nonatomic) BOOL hostAppHasBackgroundCapability;
@property (nonatomic) NSTimer *backgroundLocationServiceTimeoutTimer;
@property (nonatomic) id<MMECLLocationManagerWrapper> locationManager;

@end


SPEC_BEGIN(MMELocationManagerSpec)

describe(@"MMELocationManager", ^{
 
    __block MMELocationManager *locationManager;
    
    describe(@"- startUpdatingLocation", ^{
        
        context(@"when the host app has background capability and always permissions", ^{
            
            beforeEach(^{
                spy_on([NSBundle mainBundle]);
                [NSBundle mainBundle] stub_method(@selector(objectForInfoDictionaryKey:)).with(@"UIBackgroundModes").and_return(@[@"location"]);
                
                MMECLLocationManagerWrapper *locationManagerWrapper = [[MMECLLocationManagerWrapper alloc] init];
                spy_on(locationManagerWrapper);
                
                // Do nothing
                spy_on(locationManagerWrapper.locationManager);
                locationManagerWrapper.locationManager stub_method(@selector(setAllowsBackgroundLocationUpdates:)).and_do(^(NSInvocation *) {
                    return;
                });
                
                locationManagerWrapper stub_method(@selector(authorizationStatus)).and_return(kCLAuthorizationStatusAuthorizedAlways);
                
                spy_on([MMEDependencyManager sharedManager]);
                [MMEDependencyManager sharedManager] stub_method(@selector(locationManagerWrapperInstance)).and_return(locationManagerWrapper);                
                
                locationManager = [[MMELocationManager alloc] init];
                locationManager.delegate = nice_fake_for(@protocol(MMELocationManagerDelegate));
                
                locationManager.backgroundLocationServiceTimeoutTimer should be_nil;
            });
            
            context(@"when startUpdatingLocation is called", ^{
                
                beforeEach(^{                    
                    // call start updating location on location manager
                    [locationManager startUpdatingLocation];
                });
                
                it(@"sets itself of the delegate of the locationManagerWrapper", ^{
                    locationManager.locationManager.delegate should equal(locationManager);
                });
                
                it(@"sets the desired accuracy correctly", ^{
                    locationManager.locationManager.desiredAccuracy should equal(kCLLocationAccuracyThreeKilometers);
                });
                
                it(@"sets the distance filter correctly", ^{
                    locationManager.locationManager.distanceFilter should equal(MMELocationManagerDistanceFilter);
                });
                
                it(@"calls the location manager wrapper's start startMonitoringSignificantLocationChanges method", ^{
                    locationManager.locationManager should have_received(@selector(startMonitoringSignificantLocationChanges));
                });
                
                it(@"starts the background timer", ^{
                    locationManager.backgroundLocationServiceTimeoutTimer should_not be_nil;
                });
                
                it(@"starts updating location", ^{
                    locationManager.isUpdatingLocation should be_truthy;
                });
                
                it(@"tells the location manager wrapper to allow background location updates", ^{
                    locationManager.locationManager should have_received(@selector(setAllowsBackgroundLocationUpdates:)).with(YES);
                });
                
                it(@"tells the location manager wrapper to start updating location", ^{
                    locationManager.locationManager should have_received(@selector(startUpdatingLocation));
                });
                
                it(@"tells the location manager to notify the delegate that it started location updates", ^{
                    locationManager.delegate should have_received(@selector(locationManagerDidStartLocationUpdates:)).with(locationManager);
                });
            });
            
        });
        
    });
    
});

SPEC_END
