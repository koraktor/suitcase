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
static NSUInteger kMinImageSize;

+ (void)initialize {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0, 1.0), NO, 0.0);
    kClearImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        kMaxImageSize = 256;
        kMinImageSize = 128;
    } else {
        kMaxImageSize = 160;
        kMinImageSize = 80;
    }
}

+ (CGSize)sizeOfImageForImage:(UIImage *)image {
    if (image == nil) {
        return CGSizeMake(kMinImageSize, kMinImageSize);
    }

    CGFloat hFactor;
    CGFloat vFactor;
    if (image.size.width < kMinImageSize && image.size.height < kMinImageSize) {
        hFactor = (double) kMinImageSize / image.size.width;
        vFactor = (double) kMinImageSize / image.size.height;
    } else if (image.size.width > kMaxImageSize || image.size.height > kMaxImageSize) {
        hFactor = (double) kMaxImageSize / image.size.width;
        vFactor = (double) kMaxImageSize / image.size.height;
    } else {
        return image.size;
    }

    CGFloat factor = MIN(hFactor, vFactor);

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

- (void)adjustImageViewSize {
    CGSize imageViewSize = [SCItemImageCell sizeOfImageViewForImage:self.imageView.image];
    CGFloat originX = self.frame.size.width / 2 - imageViewSize.width / 2;
    self.imageView.frame = CGRectMake(originX, kImageMargin, imageViewSize.width, imageViewSize.height);
}

- (void)adjustToImageSize {
    void (^adjustSizes)() = ^() {
        CGRect frame = self.frame;
        frame.size = CGSizeMake(frame.size.width, [SCItemImageCell heightOfCellForImage:self.imageView.image]);
        self.frame = frame;

        [self adjustImageViewSize];
    };

    [UIView transitionWithView:self
                      duration:0.1f
                       options:UIViewAnimationOptionCurveLinear
                    animations:adjustSizes
                    completion:^(BOOL finished) {
                        [self showImage];
                    }];
}

- (void)refresh {
    UIColor *itemColor = [[self.item inventory] showColors] ? [self.item qualityColor] : nil;
    self.imageView.borderColor = itemColor;
    self.imageView.backgroundColor = itemColor;
}

- (void)setItem:(id<SCItem>)item {
    _item = item;

    UIImage *cachedImage = [SCImageCache cachedImageForItem:item];
    if (cachedImage != nil) {
        self.imageView.image = cachedImage;
        [self adjustImageViewSize];
        [self showImage];

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
                                       [weakSelf adjustImageViewSize];

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

- (void)showImage {
    if (self.imageView.hidden) {
        [self.activityIndicator stopAnimating];
        self.imageView.hidden = NO;
    }
}

@end
