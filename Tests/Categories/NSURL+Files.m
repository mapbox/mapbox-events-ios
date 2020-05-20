#import "NSURL+Files.h"
#import "NSURL+Directories.h"
#import "NSBundle+TestBundle.h"

@implementation NSURL (Files)

+(NSURL*)testPendingEventsFile {
    NSString* filename = [NSString stringWithFormat:@"%@.event", NSUUID.UUID.UUIDString];

    // Leverage Temporary Directory for easy Cleanup after use in tests
    if (@available(iOS 10.0, *)) {
        return [[[NSFileManager.defaultManager temporaryDirectory]
                 URLByAppendingPathComponent:NSBundle.testBundle.bundleIdentifier]
                URLByAppendingPathComponent:filename];
    } else {
        // Fallback on earlier versions
        return [[[NSURL cachesDirectory]
                 URLByAppendingPathComponent:NSBundle.testBundle.bundleIdentifier]
                URLByAppendingPathComponent:filename];

    };
}

@end
