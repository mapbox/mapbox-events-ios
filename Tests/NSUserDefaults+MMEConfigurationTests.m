#import <XCTest/XCTest.h>

#import "MMEConstants.h"
#import "MMEBundleInfoFake.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEDate.h"
#import "MMELogger.h"

@interface MMENSUserDefaultsTests : XCTestCase
@property (nonatomic) NSMutableDictionary *mutableDomain;

@end

// MARK: -

@implementation MMENSUserDefaultsTests

- (void)testMMEConfigSingletonReference {
    XCTAssertEqual(NSUserDefaults.mme_configuration, NSUserDefaults.mme_configuration);
}

@end
