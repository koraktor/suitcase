//
//  SCItemSetItemCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCItemSetItemCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) id <SCItem> item;
@property (nonatomic, strong) IBOutlet UILabel* nameLabel;

- (void)setItemWithDictionary:(NSDictionary *)itemDictionary;

@end
