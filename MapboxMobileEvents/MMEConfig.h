#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @Brief Platform API Config Model representative of behavior variancies
 */
@interface MMEConfig : NSObject

/*! Array of Certificate Revocations */
@property (nonatomic, copy) NSArray<NSString*>* certificateRevocationList;

/*! Telemetry Override Number Packaged NSInteger */
@property (nullable, nonatomic) NSNumber* telemetryTypeOverride;

/*! Telemetry Override Number Packaged CLLocationDistance */
@property (nullable, nonatomic) NSNumber* geofenceOverride;

/*! Telemetry Override Number Packaged NSTimeInterval */
@property (nullable, nonatomic, strong) NSNumber* backgroundStartupOverride;

/*! Config Event Tag */
@property (nullable, nonatomic, copy) NSString* eventTag;

/*!
 @Brief Initializer
 @Discussions Initializes from dictionary with data sanitization checks
 @param dictionary JSON Dictionary Model
 @param error NSError Reference for initialization Failure
 */
- (nullable instancetype)initWithDictionary:(NSDictionary<NSString*,id <NSObject>>*)dictionary
                                      error:(NSError**)error ;

@end

NS_ASSUME_NONNULL_END
