//
//  SCItemCell.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "SCItemCell.h"
#import "UIImageView+ASIHTTPRequest.h"

@implementation SCItemCell

@synthesize item = _item;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    self.imageView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.imageView.layer.shadowOpacity = 1.0;
    self.imageView.layer.shadowRadius = 5.0;

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    self.textLabel.frame = CGRectMake(53.0, 0.0, 257.0, 43.0);
}

- (void)setItem:(SCItem *)item
{
    _item = item;

    [self.imageView setImageWithURL:[item iconUrl]
                andPlaceholderImage:[UIImage imageNamed:@"item_placeholder.png"]
                    completionBlock:^(UIImage *image) {
                        CGSize size = CGSizeMake(44.0 * [[UIScreen mainScreen] scale], 44.0 * [[UIScreen mainScreen] scale]);
                        UIGraphicsBeginImageContext(size);
                        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
                        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();

                        self.imageView.image = scaledImage;
                    }];

    self.textLabel.text = item.name;
}

- (void)setShowColors:(BOOL)showColors
{
    if (showColors) {
        NSInteger itemQuality = [[[_item dictionary] objectForKey:@"quality"] integerValue];
        if (itemQuality == 3) {
            self.imageView.layer.shadowColor = [[UIColor colorWithRed:0.11 green:0.39 blue:0.82 alpha:1.0] CGColor];
        } else if (itemQuality == 5) {
            self.imageView.layer.shadowColor = [[UIColor colorWithRed:0.53 green:0.33 blue:0.82 alpha:1.0] CGColor];
        } else if (itemQuality == 7) {
            self.imageView.layer.shadowColor = [[UIColor colorWithRed:0.11 green:0.52 blue:0.17 alpha:1.0] CGColor];
        } else if (itemQuality == 11) {
            self.imageView.layer.shadowColor = [[UIColor colorWithRed:0.76 green:0.52 blue:0.17 alpha:1.0] CGColor];
        } else {
            self.imageView.layer.shadowColor = [[UIColor colorWithWhite:0.2 alpha:1.0] CGColor];
        }
    } else {
        self.imageView.layer.shadowColor = [[UIColor colorWithWhite:0.2 alpha:1.0] CGColor];
    }
}

@end
