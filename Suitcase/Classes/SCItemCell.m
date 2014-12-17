//
//  SCItemCell.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "FAKFontAwesome.h"
#import "UIImageView+AFNetworking.h"

#import "SCImageCache.h"

#import "SCItemCell.h"

static CGRect kImageViewFrame;
static UIImage *kPlaceHolderImage;

@implementation SCItemCell

+ (void)initialize
{
    CGSize iconSize = CGSizeMake(42.0, 42.0);

    kImageViewFrame = CGRectMake(6.0, 1.0, 42.0, 42.0);
    FAKIcon *placeHolderIcon = [FAKFontAwesome squareOIconWithSize:30.0];
    [placeHolderIcon addAttribute:NSForegroundColorAttributeName value:UIColor.lightGrayColor];
    kPlaceHolderImage = [placeHolderIcon imageWithSize:iconSize];
}

- (void)awakeFromNib
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.imageView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.imageView.layer.shadowOpacity = 1.0;
        self.imageView.layer.shadowRadius = 4.0;
    }

    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView = selectionView;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        selectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_selection_gradient"]];
        self.textLabel.shadowColor = [UIColor blackColor];
    } else {
        selectionView.backgroundColor = [UIColor colorWithRed:0.6 green:0.64 blue:0.7 alpha:1.0];

        self.indicatorLayer = [CALayer layer];
        self.indicatorLayer.frame = CGRectMake(1.0, 0.0, 4.0, 44.0);
        [self.layer addSublayer:self.indicatorLayer];
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
                self.indicatorLayer.backgroundColor = UIColor.clearColor.CGColor;
            } else {
                self.indicatorLayer.backgroundColor = _item.qualityColor.CGColor;;
            }
        }
    } else {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            self.imageView.layer.shadowColor = [[UIColor colorWithWhite:0.2 alpha:1.0] CGColor];
        } else {
            self.indicatorLayer.backgroundColor = UIColor.clearColor.CGColor;
            self.imageView.layer.borderWidth = 0.0;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = kImageViewFrame;
    self.textLabel.frame = CGRectMake(53.0, 0.0, self.frame.size.width - 67.0, 43.0);
}

- (void)loadImage
{
    UIImage *itemIcon = [SCImageCache cachedIconForItem:self.item];

    if (itemIcon != nil) {
        self.imageView.image = itemIcon;
        return;
    }

    __weak SCItemCell *weakSelf = self;
    id <SCItem> item = self.item;
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_item.iconUrl]
                          placeholderImage:kPlaceHolderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       if (weakSelf.item == item) {
                                           weakSelf.imageView.image = image;
                                       }

                                       [SCImageCache cacheIcon:image forItem:item];
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
#ifdef DEBUG
                                       NSLog(@"Loading item icon failed with error: %@", error.description);
#endif
                                   }];
}

- (void)setItem:(id <SCItem>)item
{
    if (![item isEqual:_item]) {
        _item = item;
        if ([item.quantity isEqual:@1]) {
            self.textLabel.text = item.name;
        } else {
            NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithString:item.quantity.stringValue];
            [labelText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, labelText.length)];
            [labelText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.0] range:NSMakeRange(0, labelText.length)];
            [labelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", item.name]]];
            self.textLabel.attributedText = labelText;
        }
        [self loadImage];
    }
}

@end
