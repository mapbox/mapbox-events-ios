#import "MMEEventLogReportViewController.h"

@interface MMEEventLogReportViewController () <WKUIDelegate, WKNavigationDelegate>

@property UIActivityIndicatorView *spinner;

@end

@implementation MMEEventLogReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:theConfiguration];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_spinner];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_spinner startAnimating];
    });
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_spinner stopAnimating];
    });
}

@end
