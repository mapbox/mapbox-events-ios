#import "MMEAPIClient+Mock.h"
#import "MMEMockEventConfig.h"

@implementation MMEAPIClient (Mock)

+(MMEAPIClient*)clientWithMockConfig {
    MMEMockEventConfig* config = [[MMEMockEventConfig alloc] init];
    return [[MMEAPIClient alloc] initWithConfig:config];
}
@end
