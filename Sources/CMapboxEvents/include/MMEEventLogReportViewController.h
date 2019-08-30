@import UIKit;
@import WebKit;

@interface MMEEventLogReportViewController : UIViewController

@property (nonatomic) WKWebView *webView;

- (void)displayHTMLFromRowsWithDataString:(NSString *)dataString;

@end

