
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface PrincipalClass : NSObject <XCTestObservation>

@end

@implementation PrincipalClass

- (instancetype)init {
    
}

@end

@implementation NSObject (PrincipalClass)

import Foundation
import XCTest

class PrincipalClass: NSObject, XCTestObservation {
    override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }
}


@end
