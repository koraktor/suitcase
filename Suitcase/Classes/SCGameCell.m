//
//  SCGameCell.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"

#import "SCGameCell.h"

@implementation SCGameCell

@synthesize game = _game;

static CGRect kImageViewFrame;
static CGRect kImageViewFrameScaled;
static CGSize kImageViewSize;
static UIImage *kPlaceHolderImage;
static CGRect kTextLabelFrame;

+ (void)initialize
{
    kImageViewFrame = CGRectMake(4.0, 4.0, 92.5, 34.5);
    kImageViewSize = CGSizeMake(92.0 * [[UIScreen mainScreen] scale], 34.5 * [[UIScreen mainScreen] scale]);
    kImageViewFrameScaled = CGRectMake(0.0, 0.0, kImageViewSize.width, kImageViewSize.height);
    kPlaceHolderImage = [UIImage imageNamed:@"game_placeholder.png"];
    kTextLabelFrame = CGRectMake(100.5, 0.0, 219.5, 43.0);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = kImageViewFrame;
    self.textLabel.frame = kTextLabelFrame;
}

- (void)loadImage
{
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_game.logoUrl]
                          placeholderImage:kPlaceHolderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       UIGraphicsBeginImageContext(kImageViewSize);
                                       [image drawInRect:kImageViewFrameScaled];
                                       UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                                       UIGraphicsEndImageContext();

                                       self.imageView.image = scaledImage;
                                   }
                                   failure:nil];
}

- (void)setGame:(SCGame *)game
{
    _game = game;

    self.textLabel.text = game.name;
}

@end
