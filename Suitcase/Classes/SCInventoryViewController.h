//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "IASKAppSettingsViewController.h"

#import "SCGame.h"

@class SCItemViewController;

@interface SCInventoryViewController : UITableViewController <IASKSettingsDelegate>

@property (strong, nonatomic) SCItemViewController *detailViewController;
@property (strong, nonatomic) SCGame *game;

- (void)loadInventory;

@end
