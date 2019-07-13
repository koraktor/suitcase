//
//  SCItemSetCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "FAKFontAwesome.h"

#import "SCItemSetCell.h"

NSString *const kSCItemSetCellHeader = @"kSCItemSetCellHeader";

@implementation SCItemSetCell

- (void)awakeFromNib {
    self.headerLabel.text = NSLocalizedString(kSCItemSetCellHeader, kSCItemSetCellHeader);

    FAKIcon *expandIcon = [FAKFontAwesome chevronCircleRightIconWithSize:16.0];
    [expandIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    self.expandIcon.image = [expandIcon imageWithSize:CGSizeMake(16.0, 16.0)];
}

- (void)setItem:(id<SCItem>)item {
    self.nameLabel.text = item.itemSet.name;
}

@end
