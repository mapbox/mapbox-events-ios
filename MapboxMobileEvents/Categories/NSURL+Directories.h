#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (Directories)

/// Application's Documents Directory
+(NSURL*)documentsDirectory;

/// Application's Cache Directory
+(NSURL*)cachesDirectory;

/// URL of Pending Events File (Used to stash/archive events that haven't been sent yet)
+(NSURL*)pendingEventsFile;

@end

NS_ASSUME_NONNULL_END
