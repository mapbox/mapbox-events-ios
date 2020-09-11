#import <XCTest/XCTest.h>
#import "NSProcessInfo+SystemInfo.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>



@interface NSProcessInfoTests : XCTestCase

@end

@implementation NSProcessInfoTests

- (void)testProcessorType {

    // CPUs sourced from machine.h
    // https://opensource.apple.com/source/xnu/xnu-792/osfmk/mach/machine.h.auto.html
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_X86 subtype:CPU_SUBTYPE_X86_ALL], @"x86_64");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_X86 subtype:CPU_SUBTYPE_X86_64_H], @"x86_64");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_X86_64 subtype:CPU_SUBTYPE_X86_ALL], @"x86_64");

    // ARM CPUs
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_ALL], @"arm");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_V6], @"armv6");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_V7], @"armv7");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_V7F], @"armv7f");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_V7S], @"armv7s");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_V7K], @"armv7k");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM subtype:CPU_SUBTYPE_ARM_V8], @"armv8");

    // ARM 64 CPUs
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM64 subtype:CPU_SUBTYPE_ARM64_ALL], @"arm64");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM64 subtype:CPU_SUBTYPE_ARM64_V8], @"arm64v8");
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:CPU_TYPE_ARM64 subtype:CPU_SUBTYPE_ARM64E], @"arm64e");
    
    // HAL 9000
    XCTAssertEqualObjects([NSProcessInfo mme_stringForProcessorType:9000 subtype:2001], @"cpu_9000_2001");
}


@end
