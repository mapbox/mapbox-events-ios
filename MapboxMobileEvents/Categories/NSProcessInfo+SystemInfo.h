#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSProcessInfo (SystemInfo)

/*! Human Readable Description of the of device processor */
+ (NSString *)mme_processorTypeDescription;

/*!
 @brief Human Readable Description of the CPU
 @param type Type of the processor
 @param subtype Subtype of the processor
 @returns Human readable Descriptin of the device processor
 @discussion Source Types provided by document https://opensource.apple.com/source/xnu/xnu-792/osfmk/mach/machine.h.auto.html
 */
+ (NSString*)mme_stringForProcessorType:(NSInteger)type subtype:(NSInteger)subtype;

@end

NS_ASSUME_NONNULL_END
