#import <Foundation/Foundation.h>

@class MMEBackgroundLocationServiceTimeoutHandler;
@protocol MMEUIApplicationWrapper;

@protocol MMEBackgroundLocationServiceTimeoutDelegate
- (BOOL)timeoutHandlerShouldCheckForTimeout:(MMEBackgroundLocationServiceTimeoutHandler *)handler;
- (void)timeoutHandlerDidTimeout:(MMEBackgroundLocationServiceTimeoutHandler *)handler;
- (void)timeoutHandlerBackgroundTaskDidExpire:(MMEBackgroundLocationServiceTimeoutHandler *)handler;

@end

@interface MMEBackgroundLocationServiceTimeoutHandler: NSObject

@property (nonatomic, weak) id<MMEBackgroundLocationServiceTimeoutDelegate> delegate;
@property (nonatomic, readonly) NSTimer *timer;
- (instancetype)initWithApplication:(id<MMEUIApplicationWrapper>)application;
- (void)startTimer;
- (void)stopTimer;
@end

