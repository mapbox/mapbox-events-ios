#import "MMEExceptionalDictionary.h"

@implementation MMEExceptionalDictionary

- (instancetype) initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt {
    return [super init];
}

- (instancetype) mutableCopy {
    [[NSException exceptionWithName:NSGenericException reason:@"testing" userInfo:nil] raise];
    return nil;
}

- (NSUInteger) count {
    return 0;
}

- (NSEnumerator *)keyEnumerator {
    return nil;
}

@end
