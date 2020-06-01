#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

// Limited functionality Location Manager that serves a purpose of validating the number of calls into locationManager methods
@interface LocationManagerCallCounter : CLLocationManager

// Call Sequence with BOOL NSNumber representation
@property (nonatomic, strong) NSMutableArray<NSNumber*>* setAllowsBackgroundLocationUpdatesCallSequence;
@property (nonatomic, assign) NSInteger startUpdatingLocationCallCount;
@property (nonatomic, assign) NSInteger stopUpdatingLocationCallCount;
@property (nonatomic, assign) NSInteger startMonitoringSignificantLocationChangesCallCount;

@end

// Specialized LocationManager configured to return WhenInUse Permissions
@interface LocationManagerCallCounterWhenInUse : LocationManagerCallCounter
@end

// Specialized LocationManager configured to return AuthorizedAlways Permissions
@interface LocationManagerCallCounterAuthorizedAlways : LocationManagerCallCounter
@end

// Specialized LocationManager configured to return Denied Permissions
@interface LocationManagerCallCounterDenied : LocationManagerCallCounter
@end

// Specialized LocationManager configured to return Restricted Permissions
@interface LocationManagerCallCounterRestricted : LocationManagerCallCounter
@end

NS_ASSUME_NONNULL_END
