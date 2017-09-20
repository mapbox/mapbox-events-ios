#import "NSBundle+MMEAdditions.h"

@implementation NSBundle (MMEAdditions)

- (BOOL)allowsBackgroundLocationMode {
    NSArray *backgroundModes = [self objectForInfoDictionaryKey:@"UIBackgroundModes"];
    return [backgroundModes containsObject:@"location"];
}

@end
