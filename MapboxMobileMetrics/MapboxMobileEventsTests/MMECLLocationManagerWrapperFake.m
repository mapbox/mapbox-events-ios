#import "MMECLLocationManagerWrapperFake.h"

@implementation MMECLLocationManagerWrapperFake

- (CLAuthorizationStatus)authorizationStatus {
    return self.stub_authorizationStatus;
}

@end
