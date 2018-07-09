#import <Foundation/Foundation.h>

@class MMEBackgroundLocationServiceTimeoutHandler;
@protocol MMEUIApplicationWrapper;

@protocol MMEBackgroundLocationServiceTimeoutHandlerDelegate
- (BOOL)timeoutHandlerShouldCheckForTimeout:(MMEBackgroundLocationServiceTimeoutHandler *)handler;
- (void)timeoutHandlerDidTimeout:(MMEBackgroundLocationServiceTimeoutHandler *)handler;
@end

@interface MMEBackgroundLocationServiceTimeoutHandler: NSObject

@property (nonatomic, weak) id<MMEBackgroundLocationServiceTimeoutHandlerDelegate> delegate;
- (instancetype)initWithApplication:(id<MMEUIApplicationWrapper>)application;
- (void)startBackgroundTimeoutTimer;
- (void)stopBackgroundTimeoutTimer;
@end

