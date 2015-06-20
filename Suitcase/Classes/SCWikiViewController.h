//
//  SCWikiViewController.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCWikiViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

@end
