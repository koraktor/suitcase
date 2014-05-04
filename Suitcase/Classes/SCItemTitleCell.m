//
//  SCItemTitleCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemTitleCell.h"

@implementation SCItemTitleCell

- (void)setItem:(id<SCItem>)item {
    CGSize itemTitleSize = [item.name sizeWithFont:[UIFont boldSystemFontOfSize:22.0]
                                 constrainedToSize:CGSizeMake(self.title.frame.size.width, CGFLOAT_MAX)
                                     lineBreakMode:NSLineBreakByWordWrapping];
    self.title.frame = CGRectMake(self.title.frame.origin.x, self.title.frame.origin.y,
                                  self.title.frame.size.width, itemTitleSize.height);
    self.subtitle.frame = CGRectMake(self.subtitle.frame.origin.x, itemTitleSize.height + 5.0,
                                     self.subtitle.frame.size.width, self.subtitle.frame.size.height);

    self.title.text = item.name;
    self.subtitle.text = item.levelText;
}

@end
