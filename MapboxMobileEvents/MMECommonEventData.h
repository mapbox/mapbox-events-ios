#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

extern NSString * const MMEApplicationStateForeground;
extern NSString * const MMEApplicationStateBackground;
extern NSString * const MMEApplicationStateInactive;
extern NSString * const MMEApplicationStateUnknown;

@interface MMECommonEventData : NSObject

@property (nonatomic) NSString * vendorId;
@property (nonatomic) NSString * model;
@property (nonatomic) NSString * osVersion;
@property (nonatomic) NSString * platform;
@property (nonatomic) NSString * device;
@property (nonatomic) CGFloat scale;

/*! @return a mutable dictionary of common event data */
+ (NSMutableDictionary *)commonEventData;

/*! @return the application state as a string */
+ (NSString *)applicationState;

@end
