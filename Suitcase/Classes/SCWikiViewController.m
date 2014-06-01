//
//  SCWikiViewController.m
//  Suitcase
//
//  Copyright (c) 2013-2014, Sebastian Staudt
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

    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    activityView.hidden = NO;
    [activityView sizeToFit];
    _activityButton = [[UIBarButtonItem alloc] initWithCustomView:activityView];

    UIFont *fontAwesome = [FAKFontAwesome iconFontWithSize:20.0];

    self.backButton.title = [[FAKFontAwesome arrowLeftIconWithSize:0.0] characterCode];
    [self.backButton setTitleTextAttributes:@{UITextAttributeFont:fontAwesome} forState:UIControlStateNormal];

    self.forwardButton.title = [[FAKFontAwesome arrowRightIconWithSize:0.0] characterCode];
    [self.forwardButton setTitleTextAttributes:@{UITextAttributeFont:fontAwesome} forState:UIControlStateNormal];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.backButton withStyle:BPBarButtonItemStyleStandardDark];
        [BPBarButtonItem customizeBarButtonItem:self.forwardButton withStyle:BPBarButtonItemStyleStandardDark];
    }
}

- (IBAction)closeWikiPage:(id)sender
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
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
