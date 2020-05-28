#import "MMEBundleInfoFake.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"

@implementation MMEBundleInfoFake

+ (MMEBundleInfoFake *)bundleWithFakeInfo:(NSDictionary *)fakeInfo {
    return [[MMEBundleInfoFake new] initWithInfoDictionary:fakeInfo];
}

-(instancetype)initWithInfoDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.infoDictionaryFake = dictionary;
    }
    return self;
}

-(instancetype)init {
    return [self initWithInfoDictionary:@{
        MMECollectionEnabledInSimulator: @YES
    }];
}

- (NSDictionary*) infoDictionary {
    if (self.infoDictionaryFake) {
        return self.infoDictionaryFake;
    }
    else return [super infoDictionary];
}

@end
