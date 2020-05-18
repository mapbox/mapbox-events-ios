#import "NSURL+Files.h"
#import "NSURL+Directories.h"
#import "NSBundle+TestBundle.h"

@implementation NSURL (Files)

+(NSURL*)testPendingEventsFile {

    // Leverage Temporary Directory for easy Cleanup after use in tests
    if (@available(iOS 10.0, *)) {
        return [[[NSFileManager.defaultManager temporaryDirectory]
                 URLByAppendingPathComponent:NSBundle.testBundle.bundleIdentifier]
                URLByAppendingPathComponent:@"pending-metrics.event"];
    } else {
        // Fallback on earlier versions
        return [[[NSURL cachesDirectory]
                 URLByAppendingPathComponent:NSBundle.testBundle.bundleIdentifier]
                URLByAppendingPathComponent:@"pending-metrics.event"];

    };
}

@end
