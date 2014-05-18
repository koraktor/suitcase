//
//  SCItemSetCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemSetCell.h"

NSString *const kSCItemSetCellHeader = @"kSCItemSetCellHeader";

@implementation SCItemSetCell

- (void)awakeFromNib {
    self.headerLabel.text = NSLocalizedString(kSCItemSetCellHeader, kSCItemSetCellHeader);
}

- (void)setItem:(id<SCItem>)item {
    self.nameLabel.text = item.itemSet.name;
}

@end
