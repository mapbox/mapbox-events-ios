@import Foundation;
@import MapboxMobileEvents;

@interface MMETimerManagerFake : MMETimerManager

@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic) id target;
@property (nonatomic) SEL selector;

- (void)triggerTimer;

@end
