//
//  SCMasterViewController.h
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCInventory.h"
#import "SCSharingController.h"
#import "SCTableViewController.h"

@class SCItemViewController;

@interface SCInventoryViewController : SCTableViewController <SCSharingController, UISearchBarDelegate, UITableViewDelegate>

@property (strong, nonatomic) id <SCInventory> inventory;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSDictionary *itemQualities;
@property (strong, nonatomic) NSArray *itemSections;
@property (strong, nonatomic) NSArray *itemTypes;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end
