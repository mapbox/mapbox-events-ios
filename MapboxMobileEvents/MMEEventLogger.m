#import "MMEEventLogger.h"
#import "MMEEvent.h"
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

- (void)displayHTMLFromRowsWithDataString:(NSString *)dataString andWebView:(WKWebView *)webView {
    NSString *chartHTML = [NSString stringWithFormat:@"<html><head><script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script><script type='text/javascript'>google.charts.load('current', {'packages':['timeline']});google.charts.setOnLoadCallback(drawChart);function drawChart() {var dataTable = new google.visualization.DataTable({cols: [{id: 'eventType', label: 'Event Type', type: 'string'},{id: 'start', label: 'Event Start Time', type: 'datetime'},{id: 'end', label: 'Event End Time', type: 'datetime'}],rows: %@});var options = {'title':'Telemetry Log Data','width':1024,'height':400,'timeline': { groupByRowLabel: true }};var chart = new google.visualization.Timeline(document.getElementById('chart_div'));chart.draw(dataTable, options);}</script></head><body><div id='chart_div'></div></body></html>", dataString];
                           
    
    [webView loadHTMLString:chartHTML baseURL:nil];
}

- (void)readAndDisplayLogFileFromDate:(NSDate *)logDate {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd";
    
    NSString *dateString = [dateFormatter stringFromDate:logDate];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    NSString *path = [docDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"telemetry_log-%@.json", dateString]];
    
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    if (jsonString != nil) {
        NSString *contents = [NSString stringWithFormat:@"[%@]", jsonString];
        
        //TODO: return a formatted datastring to display
        [self parseJSONFromFileContents:contents];
        
        //TODO: display data on a webview
    } else {
        NSLog(@"error reading file: %@", jsonString);
    }
}

- (void)parseJSONFromFileContents:(NSString *)contents {
    NSArray *JSON = [NSJSONSerialization JSONObjectWithData:[contents dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    
    if (JSON != nil) {
        for (NSDictionary *dictionary in JSON) {
            //TODO: parse it
        }
    } else {
        NSLog(@"error parsing JSON: %@", JSON);
    }
}

//class LogWebViewController: UIViewController, WKUIDelegate {
//
//    var webView: WKWebView!
//
//    override func loadView() {
//        let webConfiguration = WKWebViewConfiguration()
//        webView = WKWebView(frame: .zero, configuration: webConfiguration)
//        webView.uiDelegate = self
//        view = webView
//    }
//
//        do {
//            var timelineData = [Any]()
//
//            let file = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
//            let contents = "[\(file)]"
//
//            if let json = try JSONSerialization.jsonObject(with: contents.data(using: .utf8)!, options: []) as? [[String: Any]] {
//                for dictionary in json {
//                    if let event = dictionary["debug"] as? [String: String] {
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"
//
//                        if let date = dateFormatter.date(from: event["created"]!) {
//                            let calendar = Calendar.current
//                            let components = calendar.dateComponents([.year, .month, .day, .hour, .second], from: date)
//
//                            let debugDict = ["v": event["debug.type"]]
//                            let dateDict = ["v": "Date(\(components.year!), \(components.month!), \(components.day!), \(components.hour!), \(components.second!))"]
//                            let array = [debugDict, dateDict, dateDict]
//                            let wrapDict = ["c": array]
//
//                            timelineData.append(wrapDict)
//                        }
//                    }
//                }
//
//                if let timelineJSON = try? JSONSerialization.data(withJSONObject: timelineData, options: JSONSerialization.WritingOptions(rawValue: 0)) {
//                    let timelineJSONString = String(data: timelineJSON, encoding: .utf8)
//
//                    displayHTMLFromRows(timelineData: timelineJSONString!, webView: webView)
//                }
//
//            }
//        } catch {
//            print("Error: " + error.localizedDescription)
//        }
//
//
//
//
//    }}







@end

