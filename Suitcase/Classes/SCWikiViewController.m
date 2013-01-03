//
//  SCWikiViewController.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "SCWikiViewController.h"

@interface SCWikiViewController ()

@end

@implementation SCWikiViewController

- (IBAction)goBack:(id)sender
{
    [(UIWebView *)self.view goBack];
}

- (IBAction)goForward:(id)sender
{
    [(UIWebView *)self.view goForward];
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
    self.backButton.enabled = [webView canGoBack];
    self.forwardButton.enabled = [webView canGoForward];
}

@end
