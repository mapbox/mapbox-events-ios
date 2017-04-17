#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol MMECLLocationManagerWrapper <NSObject>

- (CLAuthorizationStatus)authorizationStatus;

@end

@interface MMECLLocationManagerWrapper : NSObject <MMECLLocationManagerWrapper>

@end
