//
//  SCItemSetCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt

//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCItemSetCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UILabel *headerLabel;
@property (nonatomic, strong) id <SCItem> item;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@end
