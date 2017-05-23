#import <UIKit/UIKit.h>

@protocol MMEUIApplicationWrapper <NSObject>

@property(nonatomic, readonly) UIApplicationState applicationState;

@end

@interface MMEUIApplicationWrapper : NSObject <MMEUIApplicationWrapper>

@end
