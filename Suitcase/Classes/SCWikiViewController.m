//
//  SCWikiViewController.m
//  Suitcase
//
//  Copyright (c) 2013-2016, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"

#import "SCWikiViewController.h"

@interface SCWikiViewController () {
    UIBarButtonItem *_activityButton;
}
@end

@implementation SCWikiViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        self.view = [[UIWebView alloc] initWithFrame:self.view.frame];
        ((UIWebView *)self.view).delegate = self;

    } else {
        self.view = [[WKWebView alloc] initWithFrame:self.view.frame];
        ((WKWebView *)self.view).navigationDelegate = self;
    }

    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    activityView.hidden = NO;
    [activityView sizeToFit];
    _activityButton = [[UIBarButtonItem alloc] initWithCustomView:activityView];

    UIFont *fontAwesome = [FAKFontAwesome iconFontWithSize:20.0];

    self.backButton.title = [[FAKFontAwesome arrowLeftIconWithSize:0.0] characterCode];
    [self.backButton setTitleTextAttributes:@{NSFontAttributeName:fontAwesome} forState:UIControlStateNormal];
    self.backButton.target = self.view;
    self.backButton.action = @selector(goBack);

    self.forwardButton.title = [[FAKFontAwesome arrowRightIconWithSize:0.0] characterCode];
    [self.forwardButton setTitleTextAttributes:@{NSFontAttributeName:fontAwesome} forState:UIControlStateNormal];
    self.forwardButton.target = self.view;
    self.forwardButton.action = @selector(goForward);

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.backButton withStyle:BPBarButtonItemStyleStandardDark];
        [BPBarButtonItem customizeBarButtonItem:self.forwardButton withStyle:BPBarButtonItemStyleStandardDark];
    }
}

- (IBAction)closeWikiPage:(id)sender
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadUrl:(NSURL *)url {
    NSURLRequest *wikiRequest = [NSURLRequest requestWithURL:url];
    if (self.view.class == WKWebView.class) {
        WKWebView *webView = (WKWebView *)self.view;
        [webView loadRequest:wikiRequest];
    } else {
        UIWebView *webView = (UIWebView *)self.view;
        if (![webView.request.URL.absoluteURL isEqual:url]) {
            [webView loadRequest:wikiRequest];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [(UIActivityIndicatorView *)_activityButton.customView stopAnimating];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    self.backButton.enabled = [webView canGoBack];
    self.forwardButton.enabled = [webView canGoForward];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [(UIActivityIndicatorView *)_activityButton.customView startAnimating];
    [self.navigationItem setRightBarButtonItem:_activityButton animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [(UIActivityIndicatorView *)_activityButton.customView stopAnimating];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    self.backButton.enabled = [webView canGoBack];
    self.forwardButton.enabled = [webView canGoForward];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [(UIActivityIndicatorView *)_activityButton.customView startAnimating];
    [self.navigationItem setRightBarButtonItem:_activityButton animated:YES];
}

@end
