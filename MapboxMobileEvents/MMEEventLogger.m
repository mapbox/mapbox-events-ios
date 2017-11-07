#import "MMEEventLogger.h"

@interface MMEEventLogger()

@property (nonatomic, copy) NSString *dateForDebugLogFile;
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) dispatch_queue_t debugLogSerialQueue;

@end

@implementation MMEEventLogger

static BOOL _enabled;

+ (void)logEvent:(MMEEvent *)event {    
    if (_enabled) {
        NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry event %@", event]);
    }
}

+ (BOOL)isEnabled {
    return _enabled;
}

+ (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
}

- (void)writeEventToLocalDebugLog:(MMEEvent *)event {
    if (!_enabled) {
        return;
    }
    
    if (!self.dateForDebugLogFile) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        self.dateForDebugLogFile = [dateFormatter stringFromDate:[NSDate date]];
    }
    
    if (!self.debugLogSerialQueue) {
        NSString *uniqueID = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        self.debugLogSerialQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@.%@.events.debugLog", appBundleID, uniqueID] UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(self.debugLogSerialQueue, ^{
        if ([NSJSONSerialization isValidJSONObject:event]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:nil];
            
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            jsonString = [jsonString stringByAppendingString:@",\n"];
            
            NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"telemetry_log-%@.json", self.dateForDebugLogFile]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if ([fileManager fileExistsAtPath:logFilePath]) {
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
            } else {
                [fileManager createFileAtPath:logFilePath contents:[jsonString dataUsingEncoding:NSUTF8StringEncoding] attributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication }];
            }
        }
    });
}


@end
