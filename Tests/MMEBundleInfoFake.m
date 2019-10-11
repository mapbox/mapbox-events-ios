#import "MMEBundleInfoFake.h"

@implementation MMEBundleInfoFake

- (NSDictionary*) infoDictionary {
    if (self.infoDictionaryFake) {
        return self.infoDictionaryFake;
    }
    else return [super infoDictionary];
}

@end
