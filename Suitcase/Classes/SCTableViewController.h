//
//  SCTableViewController.h
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCTableViewController : UITableViewController

- (void)setRefreshControlTitle:(NSString *)title;
- (IBAction)triggerRefresh:(id)sender;

@end
