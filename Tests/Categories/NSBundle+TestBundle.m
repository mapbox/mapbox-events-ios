#import "NSBundle+TestBundle.h"

@interface TestBundle: NSObject
@end

@implementation TestBundle
@end

@implementation NSBundle (TestBundle)

+ (NSBundle*)testBundle {
    return [NSBundle bundleForClass:TestBundle.self];
}


@end
