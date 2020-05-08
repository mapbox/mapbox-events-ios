#import "MMEConfig.h"
#import "MMEConstants.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSUserDefaults+MMEConfiguration_Private.h"

@implementation MMEConfig

- (instancetype)initWithDictionary:(NSDictionary<NSString*,id <NSObject>>*)dictionary
                             error:(NSError**)error {

    self = [super init];
    if (self) {

        // Inspect for restricted keys signifying data should be treated as invalid
        if ([dictionary.allKeys containsObject:MMERevokedCertKeys]) {

            NSError *restrictedKeyError = [NSError errorWithDomain:MMEErrorDomain
                                                              code:MMEErrorConfigUpdateError
                                                          userInfo:@{
                                                              NSLocalizedDescriptionKey: [
                                                                                          NSString stringWithFormat:@"Config object contains invalid key: %@",
                                                                                          MMERevokedCertKeys
                                                                                          ]

                                                          }
                                           ];
            if (restrictedKeyError && error) {
                *error = restrictedKeyError;
                return nil;
            }
        }

        // Certificate Revocation List
        id configCRL = [dictionary objectForKey:MMEConfigCRLKey];
        if ([configCRL isKindOfClass:NSArray.class]) {
            for (NSString *publicKeyHash in configCRL) {
                NSData *pinnedKeyHash = [[NSData alloc] initWithBase64EncodedString:publicKeyHash options:(NSDataBase64DecodingOptions)0];

                // Data Sanitization
                if ([pinnedKeyHash length] != CC_SHA256_DIGEST_LENGTH){

                    NSError *sha256Error = [NSError errorWithDomain:MMEErrorDomain
                                                               code:MMEErrorConfigUpdateError
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: [
                                                                                           NSString stringWithFormat:@"Hash value invalid: %@",
                                                                                           pinnedKeyHash
                                                                                           ]
                                                           }
                                            ];

                    if (error && sha256Error) {
                        *error = sha256Error;
                    }
                    return nil;
                }
            }
            _certificateRevocationList = configCRL;
        }

        // Telemetry Type Override
        id configTTO = [dictionary objectForKey:MMEConfigTTOKey];
        if ([configTTO isKindOfClass:NSNumber.class]) {
            _telemetryTypeOverride = configTTO;
        }

        // GeoFence Override
        id configGFO = [dictionary objectForKey:MMEConfigGFOKey];
        if ([configGFO isKindOfClass:NSNumber.class]) {
            CLLocationDistance gfoDistance = [configGFO doubleValue];


            if (gfoDistance >= MMECustomGeofenceRadiusMinimum &&
                gfoDistance <= MMECustomGeofenceRadiusMaximum) {
                _geofenceOverride = @(gfoDistance);
            }
        }

        // Background Startup Option
        id configBSO = [dictionary objectForKey:MMEConfigBSOKey];
        if ([configBSO isKindOfClass:NSNumber.class]) {
            NSTimeInterval bsoInterval = [configBSO doubleValue];
            if (bsoInterval > 0 && bsoInterval <= MMEStartupDelayMaximum) {
                _backgroundStartupOverride = @(bsoInterval);
            }
        }

        // Event Tag
        id tag = [dictionary objectForKey:MMEConfigTagKey];
        if ([tag isKindOfClass:NSString.class]) {
            _eventTag = tag;
        }
    }

    return self;
}

@end
