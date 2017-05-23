#import <Foundation/Foundation.h>
#import "MMECLLocationManagerWrapper.h"
#import "MMETestStub.h"

@interface MMECLLocationManagerWrapperFake : MMETestStub <MMECLLocationManagerWrapper>

@property (nonatomic, weak) id<MMECLLocationManagerWrapperDelegate> delegate;
@property (nonatomic, copy, readwrite) NSSet<__kindof CLRegion *> *monitoredRegions;
@property (nonatomic) CLAuthorizationStatus stub_authorizationStatus;

@end
