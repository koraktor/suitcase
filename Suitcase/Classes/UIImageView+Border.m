//
//  UIImageView+Border.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "UIImageView+Border.h"

@implementation UIImageView (Border)

static CGFloat kBorderWidth;
static UIColor *kDefaultColor;

+ (void)initialize {
    kBorderWidth = [[UIScreen mainScreen] scale] * 3;
    kDefaultColor = [UIColor colorWithRed:0.6 green:0.64 blue:0.71 alpha:1.0];
}

+ (CGFloat)borderWidth {
    return kBorderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.layer.borderWidth = kBorderWidth;
    self.layer.cornerRadius = 5.0;
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = 1.5;

    UIColor *newBorderColor = (borderColor == nil) ? kDefaultColor : borderColor;
    self.layer.borderColor = [newBorderColor CGColor];
}
@end
