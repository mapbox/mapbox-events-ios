#import "MMELocationManager.h"
#import "MMETestStub.h"

@interface MMELocationManagerFake : MMETestStub <MMELocationManager>

@property (nonatomic, weak) id<MMELocationManagerDelegate> delegate;
@property (nonatomic, getter=isUpdatingLocation, readonly) BOOL updatingLocation;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
