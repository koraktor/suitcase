//
//  SCGamesViewController.h
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCTableViewController.h"

@interface SCGamesViewController : SCTableViewController <UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIRefreshControl *refreshControl;

- (IBAction)triggerRefresh:(id)sender;

@end
