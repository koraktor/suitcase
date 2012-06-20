//
//  SCItemCell.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCItemCell.h"

@implementation SCItemCell

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    self.textLabel.frame = CGRectMake(53.0, 0.0, 257.0, 43.0);
}

@end
