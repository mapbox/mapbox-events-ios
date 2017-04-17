#import <Foundation/Foundation.h>
#import "MMECLLocationManagerWrapper.h"

@interface MMECLLocationManagerWrapperFake : NSObject <MMECLLocationManagerWrapper>

@property (nonatomic) CLAuthorizationStatus stub_authorizationStatus;

@end
