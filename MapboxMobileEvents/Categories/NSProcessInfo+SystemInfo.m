#import "NSProcessInfo+SystemInfo.h"

#if TARGET_OS_IOS || TARGET_OS_TVOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_MACOS
#import <AppKit/AppKit.h>
#endif

@implementation NSProcessInfo (SystemInfo)

+ (NSString *)mme_operatingSystemVersion {
    NSString *osVersion = nil;

#if TARGET_OS_IOS || TARGET_OS_TVOS
    osVersion = [NSString stringWithFormat:@"%@ %@", UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion];
#elif TARGET_OS_MACOS
    osVersion = NSProcessInfo.processInfo.operatingSystemVersionString;
#endif

    return osVersion;
}

+ (NSString*)mme_stringForProcessorType:(cpu_type_t)type subtype:(cpu_subtype_t)subtype {

    // Scratch String to build description. Ensures non-nil
    NSMutableString *processorDescription = [[NSMutableString alloc] init];

    // values for cputype and cpusubtype defined in mach/machine.h
    // https://opensource.apple.com/source/dyld/dyld-635.2/launch-cache/MachOFileAbstraction.hpp.auto.html
    if (type == CPU_TYPE_X86_64) {
        [processorDescription appendString:@"x86_64"];
    } else if (type == CPU_TYPE_X86) {
        [processorDescription appendString:@"x86"];

        switch(subtype) {
            case CPU_SUBTYPE_X86_64_ALL:
                [processorDescription appendString:@"_64"];
                break;
            case CPU_SUBTYPE_X86_ARCH1:
                [processorDescription appendString:@"_64"];
                break;
            case CPU_SUBTYPE_X86_64_H:
                [processorDescription appendString:@"_64"];
                break;
        }

    } else if (type == CPU_TYPE_ARM) {
        [processorDescription appendString:@"arm"];
        switch(subtype) {
            case CPU_SUBTYPE_ARM_V6:
                [processorDescription appendString:@"v6"];
                break;
            case CPU_SUBTYPE_ARM_V7:
                [processorDescription appendString:@"v7"];
                break;
            case CPU_SUBTYPE_ARM_V7F:
                [processorDescription appendString:@"v7f"];
                break;
            case CPU_SUBTYPE_ARM_V7S:
                [processorDescription appendString:@"v7s"];
                break;
            case CPU_SUBTYPE_ARM_V7K:
                [processorDescription appendString:@"v7k"];
                break;
            case CPU_SUBTYPE_ARM_V8:
                [processorDescription appendString:@"v8"];
                break;
        }
    } else if (type == CPU_TYPE_ARM64) {
        [processorDescription appendString:@"arm64"];
        switch(subtype)
        {
            case CPU_SUBTYPE_ARM64_V8:
                [processorDescription appendString:@"v8"];
                break;
            case CPU_SUBTYPE_ARM64E:
                [processorDescription appendString:@"e"];
                break;
        }
    }
    else {
        [processorDescription appendFormat:@"cpu_%i_%i", type, subtype];
    }

    return processorDescription;
}

+ (NSString *)mme_processorTypeDescription {
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;

    // Get Type
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);

    // Get Subtype
    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);

    return [self mme_stringForProcessorType:type subtype: subtype];
}

@end
