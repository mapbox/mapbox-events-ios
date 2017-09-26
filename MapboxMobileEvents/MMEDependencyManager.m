#import "MMEDependencyManager.h"
#import "MMECLLocationManagerWrapper.h"

static MMEDependencyManager *_sharedInstance;

@implementation MMEDependencyManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[MMEDependencyManager alloc] init];
    });
    return _sharedInstance;
}

- (MMECLLocationManagerWrapper *)locationManagerWrapperInstance {
    return [[MMECLLocationManagerWrapper alloc] init];
}

@end
