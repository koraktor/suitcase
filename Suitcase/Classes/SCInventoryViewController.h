//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCInventory.h"

@class SCItemViewController;

@interface SCInventoryViewController : UITableViewController <UITableViewDelegate>

@property (strong, nonatomic) id <SCInventory> inventory;

@end
