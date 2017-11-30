#import "MMEEventLogReportViewController.h"

@interface MMEEventLogReportViewController () <WKUIDelegate, WKNavigationDelegate>

@property UIActivityIndicatorView *spinner;

@end

@implementation MMEEventLogReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.leftBarButtonItem = backButton;
    
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

- (void)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

@end
