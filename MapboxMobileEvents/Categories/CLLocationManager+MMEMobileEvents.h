#import <CoreLocation/CoreLocation.h>

@interface CLLocationManager (MMEMobileEvents)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
void mme_linkCLLocationManagerCategory();
#pragma clang diagnostic pop

- (CLAuthorizationStatus)mme_authorizationStatus;
- (NSString *)mme_authorizationStatusString;

- (NSString *)mme_accuracyAutorizationString API_AVAILABLE(ios(14.0), macos(11.0), watchos(7.0), tvos(14.0));

@end
