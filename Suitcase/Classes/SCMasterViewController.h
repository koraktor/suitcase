//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@class SCDetailViewController;

@interface SCMasterViewController : UITableViewController

@property (strong, nonatomic) SCDetailViewController *detailViewController;

- (void)loadInventory;

@end
