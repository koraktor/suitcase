//
//  SCGameCell.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCGame.h"

@interface SCGameCell : UITableViewCell

@property (strong, nonatomic) SCGame *game;

- (void)loadImage;

@end
