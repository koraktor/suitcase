//
//  SCItemCell.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "FAKFontAwesome.h"
#import "UIImageView+AFNetworking.h"

#import "SCItemCell.h"

static CGRect kImageViewFrame;
static UIImage *kPlaceHolderImage;
static CGRect kTextLabelFrame;

@implementation SCItemCell

+ (void)initialize
{
    CGSize iconSize = CGSizeMake(42.0, 42.0);

    kImageViewFrame = CGRectMake(1.0, 1.0, 42.0, 42.0);
    FAKIcon *placeHolderIcon = [FAKFontAwesome squareOIconWithSize:30.0];
    [placeHolderIcon addAttribute:NSForegroundColorAttributeName value:UIColor.lightGrayColor];
    kPlaceHolderImage = [placeHolderIcon imageWithSize:iconSize];
    kTextLabelFrame = CGRectMake(53.0, 0.0, 257.0, 43.0);
}

- (void)awakeFromNib
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.imageView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.imageView.layer.shadowOpacity = 1.0;
        self.imageView.layer.shadowRadius = 4.0;
    } else {
        self.imageView.layer.borderWidth = 1.0;
    }

    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView = selectionView;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        selectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_selection_gradient"]];
        self.textLabel.shadowColor = [UIColor blackColor];
    } else {
        selectionView.backgroundColor = [UIColor colorWithRed:0.6 green:0.64 blue:0.7 alpha:1.0];
    }

    [super awakeFromNib];
}

- (void)setShowColors:(BOOL)showColors
{
    _showColors = showColors;

    if (_showColors) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            self.imageView.layer.shadowColor = [_item.qualityColor CGColor];
        } else {
            if (_item.qualityColor == nil) {
                self.imageView.layer.borderWidth = 0.0;
            } else {
                self.imageView.layer.borderColor = [_item.qualityColor CGColor];
                self.imageView.layer.borderWidth = 1.0;
            }
        }
    } else {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            self.imageView.layer.shadowColor = [[UIColor colorWithWhite:0.2 alpha:1.0] CGColor];
        } else {
            self.imageView.layer.borderWidth = 0.0;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = kImageViewFrame;
    self.textLabel.frame = kTextLabelFrame;
}

- (void)loadImage
{
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_item.iconUrl]
                          placeholderImage:kPlaceHolderImage
                                   success:nil
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
#ifdef DEBUG
                                       NSLog(@"Loading item icon failed with error: %@", error.description);
#endif
                                   }];
}

- (void)setItem:(id <SCItem>)item
{
    _item = item;

    self.textLabel.text = item.name;
}

@end
