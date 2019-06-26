
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface PrincipalClass : NSObject <XCTestObservation>

@end

@implementation PrincipalClass

- (instancetype)init {
    self = [super init];
    if (self) {
        [XCTestObservationCenter.sharedTestObservationCenter addTestObserver:self];
    }
    return self;
}

@end
