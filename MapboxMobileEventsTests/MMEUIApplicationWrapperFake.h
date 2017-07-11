#import <Foundation/Foundation.h>
#import "MMEUIApplicationWrapper.h"

@interface MMEUIApplicationWrapperFake : NSObject <MMEUIApplicationWrapper>

@property(nonatomic, readwrite) UIApplicationState applicationState;

@end
