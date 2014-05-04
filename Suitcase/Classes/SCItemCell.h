//
//  SCItemCell.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCItemCell : UITableViewCell

@property (strong, nonatomic) id <SCItem> item;
@property (nonatomic) BOOL showColors;

- (void)loadImage;

@end
