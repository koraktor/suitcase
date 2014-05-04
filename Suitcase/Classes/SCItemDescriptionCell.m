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

    CGSize targetSize = CGSizeMake(self.frame.size.width - 2 * self.descriptionLabel.frame.origin.x, CGFLOAT_MAX);
    CGSize labelSize = [self.descriptionLabel sizeThatFits:targetSize];
    self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x,
                                             self.descriptionLabel.frame.origin.y,
                                             labelSize.width,
                                             labelSize.height);
}

@end
