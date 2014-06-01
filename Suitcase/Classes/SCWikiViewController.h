//
//  SCWikiViewController.h
//  Suitcase
//
//  Copyright (c) 2013-2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItemViewController.h"

@interface SCWikiViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;

- (IBAction)closeWikiPage:(id)sender;

@end
