//
//  SCItemDescriptionCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemDescriptionCell.h"

@implementation SCItemDescriptionCell

- (void)awakeFromNib {
    self.descriptionLabel.highlightedShadowColor = self.descriptionLabel.shadowColor;
    self.descriptionLabel.highlightedShadowOffset = self.descriptionLabel.shadowOffset;
    self.descriptionLabel.highlightedShadowRadius = self.descriptionLabel.shadowRadius;
}

- (void)setDescriptionText:(NSAttributedString *)descriptionText {
    self.descriptionLabel.text = descriptionText;
}

@end
