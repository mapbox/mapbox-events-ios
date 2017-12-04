#import "MMEEventLogReportViewController.h"

@interface MMEEventLogReportViewController () <WKUIDelegate, WKScriptMessageHandler>

@property UIActivityIndicatorView *spinner;
@property NSString *dataString;

@end

@implementation MMEEventLogReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    [self.view addSubview:view];
    view.backgroundColor = [UIColor colorWithRed:(247.0f/255.0f) green:(247.0f/255.0f) blue:(247.0f/255.0f) alpha:1];
    view.layer.zPosition = 1;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Done" forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 20.0, 70.0, 40.0);
    [view addSubview:button];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:self name:@"complete"];
    [controller addScriptMessageHandler:self name:@"data"];
    configuration.userContentController = controller;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - view.frame.size.height) configuration:configuration];
    self.webView.UIDelegate = self;
    [self.view addSubview:self.webView];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.spinner setFrame:CGRectMake(self.view.frame.size.width/2 - self.spinner.frame.size.width/2, self.view.frame.size.height/2, self.spinner.frame.size.width, self.spinner.frame.size.height)];
    [self.view addSubview:self.spinner];
    
    [self.spinner startAnimating];
}

- (void)displayHTMLFromRowsWithDataString:(NSString *)dataString {
    self.dataString = dataString;
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"logger" ofType:@"html"]]];
    
    [self.webView loadRequest:urlReq];
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.body isEqualToString:@"complete"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
        });
    } else {
        if (self.dataString) {
            NSString *exec = [NSString stringWithFormat:@"addData(%@)",self.dataString];
            [self.webView evaluateJavaScript:exec completionHandler:nil];
        }
    }
}

- (void)doneButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:TRUE completion:nil];
}

@end

