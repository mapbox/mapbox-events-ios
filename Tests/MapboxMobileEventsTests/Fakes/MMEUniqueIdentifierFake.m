#import "MMEUniqueIdentifierFake.h"

@import Foundation;

@implementation MMEUniqueIdentifierFake

- (NSString *)rollingInstanceIdentifer {
    return @"unique-identifer";
}

@synthesize timeInterval;

@end
