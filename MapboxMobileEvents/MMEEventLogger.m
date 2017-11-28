#import "MMEEventLogger.h"
#import "MMEEvent.h"
#import "MMEEventLogReportViewController.h"
#import <WebKit/WebKit.h>

@interface MMEEventLogger()

@property (nonatomic, copy) NSString *dateForDebugLogFile;
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) dispatch_queue_t debugLogSerialQueue;

@end

@implementation MMEEventLogger

+ (instancetype)sharedLogger {
    static MMEEventLogger *_sharedLogger;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[MMEEventLogger alloc] init];
    });
    
    return _sharedLogger;
}

- (void)logEvent:(MMEEvent *)event {
    if (self.isEnabled) {
        NSLog(@"%@", [NSString stringWithFormat:@"Mapbox Telemetry event %@", event]);
        
        [self writeEventToLocalDebugLog:event];
    }
}

#pragma mark - Write to Local File

- (void)writeEventToLocalDebugLog:(MMEEvent *)event {
    if (!self.isEnabled) {
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
    
    NSDictionary *eventDict = @{event.name: event.attributes};
    
    dispatch_async(self.debugLogSerialQueue, ^{
        if ([NSJSONSerialization isValidJSONObject:eventDict]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventDict options:NSJSONWritingPrettyPrinted error:nil];
            
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

#pragma mark - HTML Generation

- (void)displayHTMLFromRowsWithDataString:(NSString *)dataString andWebView:(WKWebView *)webView {
    NSString *chartHTML = [NSString stringWithFormat:@"<html><head><script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script><script type='text/javascript'>google.charts.load('current', {'packages':['timeline']});google.charts.setOnLoadCallback(drawChart);function drawChart() {var dataTable = new google.visualization.DataTable({cols: [{id: 'eventType', label: 'Event Type', type: 'string'},{id: 'start', label: 'Event Start Time', type: 'datetime'},{id: 'end', label: 'Event End Time', type: 'datetime'}],rows: %@});var options = {'title':'Telemetry Log Data','width':1024,'height':400,'timeline': { groupByRowLabel: true }};var chart = new google.visualization.Timeline(document.getElementById('chart_div'));chart.draw(dataTable, options);}</script></head><body><div id='chart_div'></div></body></html>", dataString];
    
    [webView loadHTMLString:chartHTML baseURL:nil];
}

- (void)readAndDisplayLogFileFromDate:(NSDate *)logDate andViewController:(UIViewController *)viewController {
    MMEEventLogReportViewController *logVC = [[MMEEventLogReportViewController alloc] init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd";
    
    NSString *dateString = [dateFormatter stringFromDate:logDate];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    NSString *path = [docDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"telemetry_log-%@.json", dateString]];
    
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    if (jsonString) {
        NSString *contents = [NSString stringWithFormat:@"[%@]", jsonString];
        NSString *dataString = [self parseJSONFromFileContents:contents];
        
        [viewController presentViewController:logVC animated:YES completion:nil];
        [self displayHTMLFromRowsWithDataString:dataString andWebView:logVC.webView];
    } else {
        if (self.isEnabled) {
            NSLog(@"error reading file: %@", jsonString);
        }
    }
}

- (NSString *)parseJSONFromFileContents:(NSString *)contents {
    NSMutableArray *timelineDataArray = [[NSMutableArray alloc] init];
    NSArray *JSON = [NSJSONSerialization JSONObjectWithData:[contents dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSZ";
    
    if (JSON) {
        for (NSDictionary *dictionary in JSON) {
            NSDictionary *eventDict = [dictionary valueForKeyPath:@"debug"];
            
            if (eventDict) {
                if ([eventDict valueForKey:@"created"]) {
                    NSDate *date = [dateFormatter dateFromString:[eventDict valueForKey:@"created"]];
                    NSDateComponents *components = [[NSCalendar currentCalendar] components:
                                                    NSCalendarUnitYear |
                                                    NSCalendarUnitMonth |
                                                    NSCalendarUnitDay |
                                                    NSCalendarUnitHour |
                                                    NSCalendarUnitMinute |
                                                    NSCalendarUnitSecond fromDate:date];
                    
                    NSDictionary *debugDict = [NSDictionary dictionaryWithObject:[eventDict valueForKey:@"debug.type"] forKey:@"v"];
                    NSDictionary *dateDict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Date(%ld, %ld, %ld, %ld, %ld, %ld)", (long)components.year, (long)components.month, (long)components.day, (long)components.hour, (long)components.minute, (long)components.second] forKey:@"v"];
                    NSArray *array = @[debugDict, dateDict, dateDict];
                    NSDictionary *wrapDict = [NSDictionary dictionaryWithObject:array forKey:@"c"];
                    
                    [timelineDataArray addObject:wrapDict];
                }
            }
        }
        if ([NSJSONSerialization isValidJSONObject:timelineDataArray]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:timelineDataArray options:NSJSONWritingPrettyPrinted error:nil];
            if (jsonData) {
                return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            if (self.isEnabled) {
               NSLog(@"Invalid JSON Object: %@", timelineDataArray);
            }
        }
    } else {
        if (self.isEnabled) {
            NSLog(@"error parsing JSON: %@", JSON);
        }
    }
    return nil;
}


@end

