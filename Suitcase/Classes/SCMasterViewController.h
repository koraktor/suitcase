//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"

@class SCItemViewController;

@interface SCMasterViewController : UITableViewController <IASKSettingsDelegate>

@property (strong, nonatomic) SCItemViewController *detailViewController;

- (void)loadInventory;

@end
