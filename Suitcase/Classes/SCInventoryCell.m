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

NSString *const kSCInventoryCellLoadingFailed = @"kSCInventoryCellLoadingFailed";

static CGRect kImageViewFrame;
static CGRect kItemCountFrame;
static UIImage *kPlaceHolderImage;
static CGRect kTextLabelFrame;

+ (void)initialize
{
    kImageViewFrame = CGRectMake(4.0, 4.0, 92.5, 34.5);
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

    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    selectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_selection_gradient"]];
    self.selectedBackgroundView = selectionView;

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
                                       cell.imageView.image = image;
                                   }
                                   failure:nil];
}

- (void)setInventory:(SCInventory *)inventory
{
    _inventory = inventory;

    self.textLabel.text = inventory.game.name;
    if (![inventory isSuccessful]) {
        self.itemCountLabel.text = NSLocalizedString(kSCInventoryCellLoadingFailed, kSCInventoryCellLoadingFailed);
    } else if (inventory.slots == nil) {
        self.itemCountLabel.text = [NSString stringWithFormat:@"%d %@", [inventory.items count], NSLocalizedString(@"items", @"items")];
    } else {
        self.itemCountLabel.text = [NSString stringWithFormat:@"%d/%@ %@", [inventory.items count], inventory.slots, NSLocalizedString(@"items", @"items")];
    }

    self.contentView.alpha = ([inventory isSuccessful]) ? 1.0 : 0.6;
}

@end
