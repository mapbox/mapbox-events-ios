#import <Foundation/Foundation.h>

@class MMECLLocationManagerWrapper;

@interface MMEDependencyManager : NSObject

+ (instancetype)sharedManager;

- (MMECLLocationManagerWrapper *)locationManagerWrapperInstance;

@end
