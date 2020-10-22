#import "CLLocationManager+MMEMobileEvents.h"
#import "MMEConstants.h"

@implementation CLLocationManager (MMEMobileEvents)

void mme_linkCLLocationManagerCategory(){}

- (CLAuthorizationStatus)mme_authorizationStatus {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    #if __IPHONE_OS_VERSION_MIN_REQUIRED < 140000
    if (@available(iOS 14, macOS 11.0, watchOS 7.0, tvOS 14.0, *)) {
    #endif
        return [self authorizationStatus];
    #if __IPHONE_OS_VERSION_MIN_REQUIRED < 140000
    } else {
        return [CLLocationManager authorizationStatus];
    }
    #endif
#else
    return [CLLocationManager authorizationStatus];
#endif
}

- (NSString *)mme_authorizationStatusString {
    CLAuthorizationStatus status = [self mme_authorizationStatus];
    NSString *statusString;

    switch (status) {
        case kCLAuthorizationStatusDenied:
            statusString = MMEEventStatusDenied;
            break;
        case kCLAuthorizationStatusRestricted:
            statusString = MMEEventStatusRestricted;
            break;
        case kCLAuthorizationStatusNotDetermined:
            statusString = MMEEventStatusNotDetermined;
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            statusString = MMEEventStatusAuthorizedAlways;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = MMEEventStatusAuthorizedWhenInUse;
            break;
        default:
            statusString = MMEEventUnknown;
            break;
    }
    return statusString;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (CLAccuracyAuthorization)mme_accuracyStatus {
    return [self accuracyAuthorization];
}

- (NSString *)mme_accuracyAutorizationString {
    NSString *statusString;

    CLAccuracyAuthorization accuracy = [self accuracyAuthorization];

    switch (accuracy) {
        case CLAccuracyAuthorizationFullAccuracy:
            statusString = MMEAccuracyAuthorizationFull;
            break;
        case CLAccuracyAuthorizationReducedAccuracy:
            statusString = MMEAccuracyAuthorizationReduced;
            break;
    }

    return statusString;
}
#endif

@end
