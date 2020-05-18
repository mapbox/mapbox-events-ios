#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (Files)

/// URL of Pending Events File (Used to stash/archive events that haven't been sent yet)
+(NSURL*)testPendingEventsFile;

@end

NS_ASSUME_NONNULL_END
