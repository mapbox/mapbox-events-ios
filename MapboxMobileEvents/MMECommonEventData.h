#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const MMEApplicationStateForeground;
extern NSString * const MMEApplicationStateBackground;
extern NSString * const MMEApplicationStateInactive;
extern NSString * const MMEApplicationStateUnknown;

@interface MMECommonEventData : NSObject

@property (nonatomic) NSString * vendorId;
@property (nonatomic) NSString * model;
@property (nonatomic) NSString * iOSVersion;
@property (nonatomic) CGFloat scale;

- (NSString *)applicationState;

@end
