//
//  SCItemTitleCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCItemTitleCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subtitle;

- (void)setItem:(id <SCItem>)item;

@end
