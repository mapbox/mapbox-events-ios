#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Mock class to override CLVisit and provide expected values for read only properties */
@interface MockVisit: CLVisit

@property (nonatomic, strong) NSDate* mockArrivalDate;
@property (nonatomic, strong) NSDate* mockDepartureDate;
@property (nonatomic, assign) CLLocationCoordinate2D mockCoordinate;
@property (nonatomic, assign) CLLocationAccuracy mockHorizontalAccuracy;

-(instancetype)init NS_UNAVAILABLE;


-(instancetype)initWithArrivalDate:(NSDate*)arrivalDate
                     departureDate:(NSDate*)departureDate
                        coordinate:(CLLocationCoordinate2D)coordinate
                horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy;

@end

NS_ASSUME_NONNULL_END
