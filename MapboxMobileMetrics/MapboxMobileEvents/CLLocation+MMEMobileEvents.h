#import <CoreLocation/CoreLocation.h>

@interface CLLocation (MMEMobileEvents)

- (CLLocationDistance)roundedAltitude;
- (CLLocationAccuracy)roundedHorizontalAccuracy;
- (CLLocationDegrees)latitudeRoundedWithPrecision:(NSUInteger)precision;
- (CLLocationDegrees)longitudeRoundedWithPrecision:(NSUInteger)precision;

@end
