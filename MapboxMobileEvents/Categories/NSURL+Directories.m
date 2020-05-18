#import "NSURL+Directories.h"
#import "NSBundle+MMEMobileEvents.h"

@implementation NSURL (Directories)

+(NSURL*)documentsDirectory {
    return [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                inDomains:NSUserDomainMask][0];
}

+(NSURL*)cachesDirectory {
    return [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory
                                                inDomains:NSUserDomainMask][0];
}

+(NSURL*)pendingEventsFile {
    return [[NSURL.documentsDirectory
            URLByAppendingPathComponent:NSBundle.mme_bundle.bundleIdentifier]
            URLByAppendingPathComponent:@"pending-metrics.event"];
}
@end
