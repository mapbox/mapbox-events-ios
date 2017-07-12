#import <CoreLocation/CoreLocation.h>

@interface CLLocation (MMEMobileEvents)

void mme_linkCLLocationCategory();

- (CLLocationDistance)mme_roundedAltitude;
- (CLLocationAccuracy)mme_roundedHorizontalAccuracy;
- (CLLocationDegrees)mme_latitudeRoundedWithPrecision:(NSUInteger)precision;
- (CLLocationDegrees)mme_longitudeRoundedWithPrecision:(NSUInteger)precision;

@end
