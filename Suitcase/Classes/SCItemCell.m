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
    CGSize iconSize = CGSizeMake(44.0, 44.0);

    kImageViewFrame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    FAKIcon *suitcaseIcon = [FAKFontAwesome suitcaseIconWithSize:30.0];
    [suitcaseIcon addAttribute:NSForegroundColorAttributeName value:UIColor.lightGrayColor];
    kPlaceHolderImage = [suitcaseIcon imageWithSize:iconSize];
    kTextLabelFrame = CGRectMake(53.0, 0.0, 257.0, 43.0);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    self.imageView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.imageView.layer.shadowOpacity = 1.0;
    self.imageView.layer.shadowRadius = 4.0;

    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView = selectionView;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        selectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_selection_gradient"]];
    } else {
        selectionView.backgroundColor = [UIColor colorWithRed:0.6 green:0.64 blue:0.7 alpha:1.0];
    }

    return self;
}

- (void)changeColor
{
    if (_showColors) {
        NSInteger itemQuality = [[[_item dictionary] objectForKey:@"quality"] integerValue];
        if (itemQuality == 1) {
            self.imageView.layer.shadowColor = [[UIColor colorWithRed:0.0 green:0.39 blue:0.0 alpha:1.0] CGColor];
        } else if (itemQuality == 3) {
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

- (void)layoutSubviews
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [super layoutSubviews];
    }

    self.imageView.frame = kImageViewFrame;
    self.textLabel.frame = kTextLabelFrame;
}

- (void)loadImage
{
    __block SCItemCell *cell = self;
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[_item iconUrl]]
                          placeholderImage:kPlaceHolderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       cell.imageView.image = image;
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
#ifdef DEBUG
                                       NSLog(@"Loading item icon failed with error: %@", error.description);
#endif
                                   }];

    [self changeColor];
}

- (void)setItem:(SCItem *)item
{
    _item = item;

    self.textLabel.text = item.name;
}

@end
