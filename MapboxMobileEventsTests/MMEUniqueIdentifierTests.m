#import <XCTest/XCTest.h>
#import "MMEUniqueIdentifier.h"

@interface MMEUniqueIdentifier (Test)

@property (nonatomic) NSDate *instanceIDRotationDate;

@end

@interface MMEUniqueIdentifierTests : XCTestCase
@end

@implementation MMEUniqueIdentifierTests

- (void)testRollingInstanceIdentifier {
    MMEUniqueIdentifier *uniqueIdentifier = [[MMEUniqueIdentifier alloc] initWithTimeInterval:3600];
    
    NSString *firstId = [uniqueIdentifier rollingInstanceIdentifer];
    NSString *secondId = [uniqueIdentifier rollingInstanceIdentifer];
    XCTAssertEqualObjects(firstId, secondId);
    
    uniqueIdentifier.instanceIDRotationDate = [NSDate distantPast];
    NSString *thirdId = [uniqueIdentifier rollingInstanceIdentifer];
    XCTAssertNotEqualObjects(secondId, thirdId);    
}

@end
