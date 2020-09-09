#import <XCTest/XCTest.h>

#import <MapboxMobileEvents/MMEUniqueIdentifier.h>

@interface MMEUniqueIdentifier (Spec)
@property (nonatomic) NSDate *instanceIDRotationDate;
@end

@interface MMEUniqueIdentifierTests : XCTestCase
@property (nonatomic) NSString *firstId;
@property (nonatomic) MMEUniqueIdentifier *uniqueIdentifier;
@end

@implementation MMEUniqueIdentifierTests

- (void)setUp {
    self.uniqueIdentifier = [[MMEUniqueIdentifier alloc] initWithTimeInterval:3600];
    self.firstId = [self.uniqueIdentifier rollingInstanceIdentifer];
}

- (void)testDateThresholdNotPassed {
    XCTAssert([self.uniqueIdentifier.rollingInstanceIdentifer isEqualToString:self.firstId]);
}

- (void)testDateThresholdPassed {
    self.uniqueIdentifier.instanceIDRotationDate = [NSDate distantPast];
    XCTAssertFalse([self.uniqueIdentifier.rollingInstanceIdentifer isEqualToString:self.firstId]);
}

@end
