//
//  SCWikiViewController.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
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
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    activityView.hidden = NO;
    [activityView sizeToFit];
    _activityButton = [[UIBarButtonItem alloc] initWithCustomView:activityView];

    UIFont *fontAwesome = [FAKFontAwesome iconFontWithSize:20.0];

    self.backButton.title = [[FAKFontAwesome arrowLeftIconWithSize:0.0] characterCode];
    [self.backButton setTitleTextAttributes:@{UITextAttributeFont:fontAwesome} forState:UIControlStateNormal];
    [BPBarButtonItem customizeBarButtonItem:self.backButton withStyle:BPBarButtonItemStyleStandardDark];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.backButton withStyle:BPBarButtonItemStyleStandardDark];
        [BPBarButtonItem customizeBarButtonItem:self.forwardButton withStyle:BPBarButtonItemStyleStandardDark];
    }

    [super awakeFromNib];
}

- (IBAction)goBack:(id)sender
{
    [(UIWebView *)self.view goBack];
}

- (IBAction)goForward:(id)sender
{
    [(UIWebView *)self.view goForward];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
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
