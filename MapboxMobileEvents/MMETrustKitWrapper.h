#import <Foundation/Foundation.h>

@interface MMETrustKitWrapper : NSObject

+ (BOOL)isInitialized;
+ (void)setInitialized:(BOOL)initialized;

+ (void)configureCertificatePinningValidation;


@end
