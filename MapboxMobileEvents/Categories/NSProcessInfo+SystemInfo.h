#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSProcessInfo (SystemInfo)

/*! Human readable description of the Operating system and version */
+ (NSString *)mme_operatingSystemVersion;

/*! Human readable Description of the of device processor */
+ (NSString *)mme_processorTypeDescription;

/*!
 @brief Human readable Description of the CPU
 @param type Type of the processor
 @param subtype Subtype of the processor
 @returns Human readable Descriptin of the device processor
 @discussion Source Types provided by document https://opensource.apple.com/source/xnu/xnu-792/osfmk/mach/machine.h.auto.html
 */
+ (NSString*)mme_stringForProcessorType:(cpu_type_t)type subtype:(cpu_subtype_t)subtype;

@end

NS_ASSUME_NONNULL_END
