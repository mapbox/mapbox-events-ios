#import "MMETestStub.h"

@implementation MMETestStub

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selectors = [NSMutableSet set];
        _argumentsBySelector = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)received:(SEL)selector withArguments:(NSArray *)arguments {
    NSValue *lookup = [NSValue valueWithPointer:selector];
    BOOL selectorCalled = [self.selectors containsObject:lookup];
    BOOL argumentsPassed = [self.argumentsBySelector[lookup] isEqualToArray:arguments];
    return selectorCalled && argumentsPassed;
}

- (void)store:(SEL)sel args:(NSArray *)args {
    NSValue *method = [NSValue valueWithPointer:sel];
    self.argumentsBySelector[method] = args;
    [self.selectors addObject:method];
}

@end
