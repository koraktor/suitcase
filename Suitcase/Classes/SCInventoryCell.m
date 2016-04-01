//
//  SCGameCell.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import "UIImageView+AFNetworking.h"

#import "SCImageCache.h"

#import "SCInventoryCell.h"

@implementation SCInventoryCell

NSString *const kSCInventoryCellLoadingFailed = @"kSCInventoryCellLoadingFailed";
NSString *const kSCInventoryCellLoadingRetrying = @"kSCInventoryCellLoadingRetrying";

static CGRect kImageViewFrame;
static UIImage *kPlaceHolderImage;
static CGRect kTextLabelFrame;

+ (void)initialize
{
    kImageViewFrame = CGRectMake(4.0, 4.0, 92.5, 34.5);
    kPlaceHolderImage = [UIImage imageNamed:@"game_placeholder.png"];
    kTextLabelFrame = CGRectMake(100.5, 4.0, 219.5, 25.0);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    _itemCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _itemCountLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _itemCountLabel.backgroundColor = [UIColor clearColor];
    _itemCountLabel.textAlignment = NSTextAlignmentRight;
    _itemCountLabel.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    _itemCountLabel.font = [UIFont systemFontOfSize:13.0];
    _itemCountLabel.shadowColor = [UIColor blackColor];
    _itemCountLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    [self.contentView addSubview:_itemCountLabel];

    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView = selectionView;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        selectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_selection_gradient"]];
    } else {
        selectionView.backgroundColor = [UIColor colorWithRed:0.6 green:0.64 blue:0.7 alpha:1.0];
    }

    return self;
}

- (NSString *)accessibilityLabel {
    return _inventory.game.name;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.imageView.frame = kImageViewFrame;
    self.textLabel.frame = kTextLabelFrame;
    [self.textLabel sizeToFit];
}

- (void)loadImage
{
    UIImage *cachedLogo = [SCImageCache cachedLogoForGame:self.inventory.game];
    if (cachedLogo != nil) {
        self.imageView.image = cachedLogo;
        return;
    }

    __block SCInventoryCell *cell = self;
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_inventory.game.logoUrl]
                          placeholderImage:kPlaceHolderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       cell.imageView.image = image;

                                       [SCImageCache cacheLogo:image forGame:cell.inventory.game];
                                   }
                                   failure:nil];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    _itemCountLabel.frame = CGRectMake(100.5, 25.0, self.frame.size.width - 102.0, 17.0);
}

- (void)setInventory:(id <SCInventory>)inventory
{
    self.imageView.image = nil;
    _inventory = inventory;

    self.textLabel.text = inventory.game.name;
    if (inventory.isRetrying) {
        self.itemCountLabel.text = NSLocalizedString(kSCInventoryCellLoadingRetrying, kSCInventoryCellLoadingRetrying);
    } else if (![inventory isSuccessful]) {
        self.itemCountLabel.text = NSLocalizedString(kSCInventoryCellLoadingFailed, kSCInventoryCellLoadingFailed);
    } else if ([inventory.slots isEqualToNumber:@0]) {
        self.itemCountLabel.text = [NSString stringWithFormat:@"%lu %@", (unsigned long) [inventory.items count], NSLocalizedString(@"items", @"items")];
    } else {
        self.itemCountLabel.text = [NSString stringWithFormat:@"%lu/%@ %@", (unsigned long) [inventory.items count], inventory.slots, NSLocalizedString(@"items", @"items")];
    }

    self.contentView.alpha = ([inventory isSuccessful]) ? 1.0 : 0.6;
}

@end
