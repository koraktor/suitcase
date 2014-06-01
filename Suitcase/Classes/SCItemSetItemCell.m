//
//  SCItemSetItemCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "FAKFontAwesome.h"
#import "UIImageView+AFNetworking.h"

#import "SCImageCache.h"

#import "SCItemSetItemCell.h"

@interface SCItemSetItemCell () {
    NSURL *_imageUrl;
}
@end

@implementation SCItemSetItemCell

static UIImage *kPlaceHolderImage;

+ (void)initialize
{
    CGSize iconSize = CGSizeMake(42.0, 42.0);

    FAKIcon *placeHolderIcon = [FAKFontAwesome squareOIconWithSize:30.0];
    [placeHolderIcon addAttribute:NSForegroundColorAttributeName value:UIColor.lightGrayColor];
    kPlaceHolderImage = [placeHolderIcon imageWithSize:iconSize];
}

- (void)loadImage
{
    NSString *iconIdentifier = [[[_imageUrl relativeString] lastPathComponent] stringByDeletingPathExtension];
    UIImage *itemIcon = [SCImageCache cachedImageForIdentifier:iconIdentifier];

    if (itemIcon != nil) {
        self.imageView.image = itemIcon;
        return;
    }

    __weak SCItemSetItemCell *weakSelf = self;
    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_imageUrl]
                          placeholderImage:kPlaceHolderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.imageView.image = image;

                                       [SCImageCache cacheImage:image forIdentifier:iconIdentifier];
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
#ifdef DEBUG
                                       NSLog(@"Loading item icon failed with error: %@", error.description);
#endif
                                   }];
}

- (void)setItemWithDictionary:(NSDictionary *)itemDictionary {
    self.nameLabel.text = itemDictionary[@"name"];
    _imageUrl = itemDictionary[@"imageUrl"];
    [self loadImage];

}

@end
