//
//  SCItemCell.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "FontAwesomeKit.h"
#import "UIImageView+AFNetworking.h"

#import "SCItemCell.h"

static CGRect kImageViewFrame;
static UIImage *kPlaceHolderImage;
static CGRect kTextLabelFrame;

@implementation SCItemCell

+ (void)initialize
{
    NSDictionary *iconAttributes = @{
        FAKImageAttributeRect: [NSValue valueWithCGRect:CGRectMake(7.0, 7.0, 44.0, 44.0)],
        FAKImageAttributeForegroundColor: UIColor.lightGrayColor
    };
    CGSize iconSize = CGSizeMake(44.0, 44.0);

    kImageViewFrame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    kPlaceHolderImage = [FontAwesomeKit imageForIcon:FAKIconBriefcase
                                           imageSize:iconSize
                                            fontSize:30.0
                                          attributes:iconAttributes];
    kTextLabelFrame = CGRectMake(53.0, 0.0, 257.0, 43.0);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    self.imageView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.imageView.layer.shadowOpacity = 1.0;
    self.imageView.layer.shadowRadius = 4.0;

    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    selectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_selection_gradient"]];
    self.selectedBackgroundView = selectionView;

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
    [super layoutSubviews];

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
                                   failure:nil];

    [self changeColor];
}

- (void)setItem:(SCItem *)item
{
    _item = item;

    self.textLabel.text = item.name;
}

@end
