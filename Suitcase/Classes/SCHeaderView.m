//
//  SCHeaderView.m
//  Suitcase
//
//  Copyright (c) 2015, Sebastian Staudt
//

#import "SCHeaderView.h"

@implementation SCHeaderView

+ (UIColor *)defaultBackgroundColor {
    return [UIColor colorWithRed:0.5372 green:0.6196 blue:0.7294 alpha:1.0];
}

+ (UIColor *)defaultGradientColor {
    return [UIColor colorWithRed:0.2118 green:0.2392 blue:0.2706 alpha:1.0];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];

    self.backgroundColor = UIColor.clearColor;

    self.contentView.backgroundColor = UIColor.clearColor;
    self.contentView.autoresizingMask = UIViewAutoresizingNone;
    self.contentView.opaque = NO;
    self.textLabel.autoresizingMask = UIViewAutoresizingNone;

    self.textLabel.backgroundColor = UIColor.clearColor;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.textColor = UIColor.whiteColor;

    CGFloat fontSize = 16.0;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.alpha = 0.8f;
        self.textLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    } else {
        self.textLabel.font = [UIFont systemFontOfSize:fontSize];
    }

    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    CGFloat white;
    if (![backgroundColor getWhite:&white alpha:nil]) {
        const CGFloat *colorComponents = CGColorGetComponents(backgroundColor.CGColor);
        white = ((colorComponents[0] * 299) + (colorComponents[1] * 587) + (colorComponents[2] * 114)) / 1000;
    }
    white = (white < 0.7) ? 0.9 : 0.1;
    self.textLabel.textColor = [UIColor colorWithWhite:white alpha:1.0];

    UIColor *gradientColor;
    if (backgroundColor == [SCHeaderView defaultBackgroundColor]) {
        gradientColor = [SCHeaderView defaultGradientColor];
    } else {
        struct CGColorSpace *colorSpace = CGColorGetColorSpace(backgroundColor.CGColor);
        if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome) {
            [backgroundColor getWhite:&white alpha:nil];
            gradientColor = [UIColor colorWithWhite:white - 0.3 alpha:1.0];
        } else {
            CGFloat alpha;
            CGFloat brightness;
            CGFloat hue;
            CGFloat saturation;
            [backgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
            brightness -= 0.3;
            gradientColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
        }
    }

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = @[ (id)[backgroundColor CGColor], (id)[gradientColor CGColor] ];
        [self.backgroundView.layer addSublayer:gradient];

        self.backgroundView.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.backgroundView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.backgroundView.layer.shadowOpacity = 0.5f;
        self.backgroundView.layer.shadowRadius = 3.25f;
        self.backgroundView.layer.masksToBounds = NO;
    } else {
        self.backgroundView.backgroundColor = backgroundColor;
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        if (frame.size.height != 0) {
            self.textLabel.center = self.center;
            self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, 0.0, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
        }
    }
}

@end
