#import "MockVisit.h"

@implementation MockVisit

-(instancetype)initWithArrivalDate:(NSDate*)arrivalDate
                     departureDate:(NSDate*)departureDate
                        coordinate:(CLLocationCoordinate2D)coordinate
                horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy {

    if (self = [super init]){
        self.mockArrivalDate = arrivalDate;
        self.mockDepartureDate = departureDate;
        self.mockCoordinate = coordinate;
        self.mockHorizontalAccuracy = horizontalAccuracy;
    }
    return self;
}

-(NSDate*)arrivalDate {
    return self.mockArrivalDate;
}

-(NSDate*)departureDate {
    return self.mockDepartureDate;
}

-(CLLocationCoordinate2D)coordinate {
    return self.mockCoordinate;
}

-(CLLocationAccuracy)horizontalAccuracy {
    return self.mockHorizontalAccuracy;
}

@end
