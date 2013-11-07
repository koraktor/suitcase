//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "IASKAppSettingsViewController.h"

#import "SCInventory.h"

@class SCItemViewController;

@interface SCInventoryViewController : UITableViewController <UITableViewDelegate>

@property (strong, nonatomic) SCItemViewController *detailViewController;
@property (strong, nonatomic) SCInventory *inventory;

@end
