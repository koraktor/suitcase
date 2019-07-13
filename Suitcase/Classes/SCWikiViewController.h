//
//  SCWikiViewController.h
//  Suitcase
//
//  Copyright (c) 2013-2015, Sebastian Staudt
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

#import "SCItemViewController.h"

@interface SCWikiViewController : UIViewController <WKNavigationDelegate, UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;

- (IBAction)closeWikiPage:(id)sender;
- (void)loadUrl:(NSURL *)url;

@end
