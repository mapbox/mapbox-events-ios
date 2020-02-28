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

- (CLLocationAccuracy)mme_roundedSpeedAccuracy {
    if (@available(iOS 13.4, *)) {
        return round(self.speedAccuracy);
    }
    return 0;
}

- (CLLocationAccuracy)mme_roundedCourseAccuracy {
    if (@available(iOS 13.4, *)) {
        return round(self.courseAccuracy);
    }
    return 0;
}

- (CLLocationDegrees)mme_latitudeRoundedWithPrecision:(NSUInteger)precision {
    return [self value:self.coordinate.latitude withPrecision:precision];
}

- (CLLocationDegrees)mme_longitudeRoundedWithPrecision:(NSUInteger)precision {
    return [self value:self.coordinate.longitude withPrecision:precision];
}

- (CLLocationDegrees)value:(CLLocationDegrees)value withPrecision:(NSUInteger)precision {
    double accuracy = pow(10.0, precision);
    return floor(value * accuracy) / accuracy;
}

@end
