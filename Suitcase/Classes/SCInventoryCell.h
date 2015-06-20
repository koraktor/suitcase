//
//  SCGameCell.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCInventory.h"

@interface SCInventoryCell : UITableViewCell

@property (strong, nonatomic) SCInventory *inventory;
@property (strong, nonatomic) UILabel *itemCountLabel;

- (void)loadImage;

@end
