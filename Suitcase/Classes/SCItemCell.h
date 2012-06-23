//
//  SCItemCell.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCItemCell : UITableViewCell

@property (strong, nonatomic) SCItem *item;

- (void)setShowColors:(BOOL)showColors;

@end
