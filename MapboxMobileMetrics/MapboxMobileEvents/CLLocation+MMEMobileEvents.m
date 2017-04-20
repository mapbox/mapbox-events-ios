#import "CLLocation+MMEMobileEvents.h"

@implementation CLLocation (MMEMobileEvents)

- (CLLocationDistance)roundedAltitude {
    return round(self.altitude);
}

- (CLLocationAccuracy)roundedHorizontalAccuracy {
    return round(self.horizontalAccuracy);
}

- (CLLocationDegrees)latitudeRoundedWithPrecision:(NSUInteger)precision {
    return [self value:self.coordinate.latitude withPrecision:precision];
}

- (CLLocationDegrees)longitudeRoundedWithPrecision:(NSUInteger)precision {
    return [self value:self.coordinate.longitude withPrecision:precision];
}

- (CLLocationDegrees)value:(CLLocationDegrees)value withPrecision:(NSUInteger)precision {
    double accuracy = pow(10.0, precision);
    return floor(value * accuracy) / accuracy;
}

@end
