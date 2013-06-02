//
//  SCGameCell.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"

#import "SCInventoryCell.h"

@implementation SCInventoryCell

@synthesize inventory = _inventory;
@synthesize itemCountLabel = _itemCountLabel;

static CGRect kImageViewFrame;
static CGRect kImageViewFrameScaled;
static CGSize kImageViewSize;
static CGRect kItemCountFrame;
static UIImage *kPlaceHolderImage;
static CGRect kTextLabelFrame;

+ (void)initialize
{
    kImageViewFrame = CGRectMake(4.0, 4.0, 92.5, 34.5);
    kImageViewSize = CGSizeMake(92.0 * [[UIScreen mainScreen] scale], 34.5 * [[UIScreen mainScreen] scale]);
    kImageViewFrameScaled = CGRectMake(0.0, 0.0, kImageViewSize.width, kImageViewSize.height);
    kItemCountFrame = CGRectMake(100.5, 25.0, 218.0, 17.0);
    kPlaceHolderImage = [UIImage imageNamed:@"game_placeholder.png"];
    kTextLabelFrame = CGRectMake(100.5, 0.0, 219.5, 25.0);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    _itemCountLabel = [[UILabel alloc] initWithFrame:kItemCountFrame];
    _itemCountLabel.backgroundColor = [UIColor clearColor];
    _itemCountLabel.textAlignment = NSTextAlignmentRight;
    _itemCountLabel.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    _itemCountLabel.font = [UIFont systemFontOfSize:13.0];
    _itemCountLabel.shadowColor = [UIColor blackColor];
    [self.contentView addSubview:_itemCountLabel];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = kImageViewFrame;
    self.textLabel.frame = kTextLabelFrame;
}

- (void)loadImage
{
    __block SCInventoryCell *cell = self;
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_inventory.game.logoUrl]
                          placeholderImage:kPlaceHolderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       UIGraphicsBeginImageContext(kImageViewSize);
                                       [image drawInRect:kImageViewFrameScaled];
                                       UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                                       UIGraphicsEndImageContext();

                                       cell.imageView.image = scaledImage;
                                   }
                                   failure:nil];
}

- (void)setInventory:(SCInventory *)inventory
{
    _inventory = inventory;

    self.textLabel.text = inventory.game.name;
    self.itemCountLabel.text = [NSString stringWithFormat:@"%d items", [inventory.items count]];

    self.contentView.alpha = ([inventory isSuccessful]) ? 1.0 : 0.6;
}

@end
