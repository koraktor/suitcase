//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@class SCItemViewController;

@interface SCMasterViewController : UITableViewController

@property (strong, nonatomic) SCItemViewController *detailViewController;

- (void)loadInventory;

@end
