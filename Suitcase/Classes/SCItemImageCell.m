//
//  SCItemImageCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "UIImageView+AFNetworking.h"

#import "UIImageView+Border.h"
#import "SCImageCache.h"

#import "SCItemImageCell.h"

@implementation SCItemImageCell

static UIImage *kClearImage;
static NSUInteger kImageMargin = 16;
static NSUInteger kImagePadding = 8;
static NSUInteger kMaxImageSize;

+ (void)initialize {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0, 1.0), NO, 0.0);
    kClearImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        kMaxImageSize = 256;
    } else {
        kMaxImageSize = 160;
    }
}

+ (CGSize)sizeOfImageForImage:(UIImage *)image {
    CGFloat hFactor = (double) kMaxImageSize / image.size.width;
    CGFloat vFactor = (double) kMaxImageSize / image.size.height;
    CGFloat factor =  MIN(1, MIN(hFactor, vFactor));

    return CGSizeMake(factor * image.size.width, factor * image.size.height);
}

+ (CGSize)sizeOfImageViewForImage:(UIImage *)image {
    CGSize imageSize = [SCItemImageCell sizeOfImageForImage:image];


    return CGSizeMake(imageSize.width + 2 * [UIImageView borderWidth] + 2 * kImagePadding,
                      imageSize.height + 2 * [UIImageView borderWidth] + 2 * kImagePadding);
}

+ (CGFloat)heightOfCellForImage:(UIImage *)image {
    return [SCItemImageCell sizeOfImageViewForImage:image].height + 2 * kImageMargin;
}

- (void)refresh {
    UIColor *borderColor = [[self.item inventory] showColors] ? [self.item qualityColor] : nil;
    [self.imageView setBorderColor:borderColor];
}

- (void)setItem:(id<SCItem>)item {
    _item = item;

    UIImage *cachedImage = [SCImageCache cachedImageForItem:item];
    if (cachedImage != nil) {
        self.imageView.image = cachedImage;

        CGSize imageViewSize = [SCItemImageCell sizeOfImageViewForImage:cachedImage];
        CGFloat originX = self.frame.size.width / 2 - imageViewSize.width / 2;
        self.imageView.frame = CGRectMake(originX, kImageMargin,
                                          imageViewSize.width, imageViewSize.height);

        if (self.imageView.hidden) {
            [self.activityIndicator stopAnimating];
            self.imageView.hidden = NO;
        }

        return;
    }

    self.imageView.hidden = YES;
    [self.activityIndicator startAnimating];

    __block UIImageView *imageView = self.imageView;
    __weak typeof(self) weakSelf = self;

    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[self.item imageUrl]]
                          placeholderImage:kClearImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       CGSize imageSize = [SCItemImageCell sizeOfImageForImage:image];

                                       UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
                                       [image drawInRect:CGRectMake(0.0, 0.0, imageSize.width, imageSize.height)];
                                       UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
                                       UIGraphicsEndImageContext();

                                       imageView.image = resizedImage;
                                       [SCImageCache cacheImage:resizedImage forItem:item];

                                       CGSize imageViewSize = [SCItemImageCell sizeOfImageViewForImage:image];
                                       CGFloat originX = weakSelf.frame.size.width / 2 - imageViewSize.width / 2;
                                       imageView.frame = CGRectMake(originX, kImageMargin,
                                                                    imageViewSize.width, imageViewSize.height);

                                       if (request != nil) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [[NSNotificationCenter defaultCenter] postNotificationName:@"itemImageLoaded" object:weakSelf];
                                           });
                                       }
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       weakSelf.hidden = YES;
                                   }];
}

@end
