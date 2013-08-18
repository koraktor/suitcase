//
//  SCItemImageView.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>
#import "UIImageView+AFNetworking.h"

#import "SCItemImageView.h"

@implementation SCItemImageView

static NSUInteger kMaxImageSize;

+ (void)initialize {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        kMaxImageSize = 256;
    } else {
        kMaxImageSize = 128;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.layer.borderColor = [[UIColor colorWithRed:0.6 green:0.64 blue:0.71 alpha:1.0] CGColor];
        self.layer.borderWidth = [[UIScreen mainScreen] scale] * self.layer.frame.size.width / 50;
        self.layer.cornerRadius = 5.0;
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 1.5;
    }

    return self;
}

- (UIImageView *)imageView {
    UIImageView *imageView;

    if ([self.subviews count] == 1) {
        CGRect rect = CGRectInset(self.bounds, self.layer.borderWidth, self.layer.borderWidth);
        imageView = [[UIImageView alloc] initWithFrame:rect];
        imageView.layer.cornerRadius = 5.0;
        imageView.clipsToBounds = YES;
        UIView *quantityLabel = self.subviews[0];
        [quantityLabel removeFromSuperview];
        [self addSubview:imageView];
        [self addSubview:quantityLabel];
    } else {
        imageView = [self.subviews objectAtIndex:0];
    }

    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    return imageView;
}

- (void)setImageWithURL:(NSURL *)url
{
    __block UIImageView *imageView = self.imageView;

    [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:url]
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       NSUInteger imageHeight = image.size.height;
                                       NSUInteger imageWidth  = image.size.width;
                                       if (imageWidth > kMaxImageSize) {
                                           imageHeight = round((double) imageHeight * ((double) kMaxImageSize / imageWidth));
                                           imageWidth  = kMaxImageSize;
                                       } else {
                                           imageHeight = MIN(imageHeight, kMaxImageSize);
                                       }
                                       self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, imageWidth, imageHeight);
                                       imageView.image = image;
                                       self.hidden = NO;
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       self.hidden = YES;
                                   }];
}

@end
