#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"


FOUNDATION_EXPORT const NSString *kMMEPinnedDomains;
FOUNDATION_EXPORT const NSString *kMMEPublicKeyHashes;
FOUNDATION_EXPORT const NSString *kMMEExcludeSubdomainFromParentPolicy;

@interface MMEPinningConfigurationProvider : NSObject

+ (MMEPinningConfigurationProvider *)pinningConfigProviderWithConfiguration:(MMEEventsConfiguration *)configuration;

@property (nonatomic, readonly) NSDictionary *pinningConfig; // Dictionary<Domain, Dictionary<Keys, Array|Number>>

@end
