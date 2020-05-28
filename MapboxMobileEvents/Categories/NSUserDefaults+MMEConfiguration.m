#import <Foundation/Foundation.h>
#import "NSUserDefaults+MMEConfiguration_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSUserDefaults (MME)

+ (instancetype)mme_configuration {
    static NSUserDefaults *eventsConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventsConfiguration = [NSUserDefaults.alloc initWithSuiteName:MMEConfigurationDomain];
    });

    return eventsConfiguration;
}

@end

NS_ASSUME_NONNULL_END
