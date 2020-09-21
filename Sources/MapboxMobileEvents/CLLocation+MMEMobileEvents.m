#import "CLLocation+MMEMobileEvents.h"

@implementation CLLocation (MMEMobileEvents)

void mme_linkCLLocationCategory(){}

- (CLLocationSpeed)mme_roundedSpeed {
    return round(self.speed);
}

- (CLLocationDirection)mme_roundedCourse {
    return round(self.course);
}

- (CLLocationDistance)mme_roundedAltitude {
    return round(self.altitude);
}

- (CLLocationAccuracy)mme_roundedHorizontalAccuracy {
    return round(self.horizontalAccuracy);
}

- (CLLocationAccuracy)mme_roundedVerticalAccuracy {
    return round(self.verticalAccuracy);
}

- (CLLocationDegrees)mme_latitudeRoundedWithPrecision:(NSUInteger)precision {
    return [self mme_value:self.coordinate.latitude withPrecision:precision];
}

- (CLLocationDegrees)mme_longitudeRoundedWithPrecision:(NSUInteger)precision {
    return [self mme_value:self.coordinate.longitude withPrecision:precision];
}

- (CLLocationDegrees)mme_value:(CLLocationDegrees)value withPrecision:(NSUInteger)precision {
    double accuracy = pow(10.0, precision);
    return floor(value * accuracy) / accuracy;
}

@end
