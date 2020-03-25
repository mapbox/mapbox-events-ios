#import <CoreLocation/CoreLocation.h>

@interface CLLocation (MMEMobileEvents)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
void mme_linkCLLocationCategory();
#pragma clang diagnostic pop

- (CLLocationSpeed)mme_roundedSpeed;
- (CLLocationDirection)mme_roundedCourse;
- (CLLocationDistance)mme_roundedAltitude;
- (CLLocationAccuracy)mme_roundedHorizontalAccuracy;
- (CLLocationAccuracy)mme_roundedVerticalAccuracy;
- (CLLocationAccuracy)mme_roundedSpeedAccuracy API_AVAILABLE(ios(13.4));
- (CLLocationAccuracy)mme_roundedCourseAccuracy API_AVAILABLE(ios(13.4));
- (CLLocationDegrees)mme_latitudeRoundedWithPrecision:(NSUInteger)precision;
- (CLLocationDegrees)mme_longitudeRoundedWithPrecision:(NSUInteger)precision;

@end
