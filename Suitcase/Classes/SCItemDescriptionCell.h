//
//  SCItemDescriptionCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"

@interface SCItemDescriptionCell : UICollectionViewCell <TTTAttributedLabelDelegate>

@property (strong, nonatomic) IBOutlet TTTAttributedLabel *descriptionLabel;

- (void)setDescriptionText:(NSAttributedString *)descriptionText;

@end
