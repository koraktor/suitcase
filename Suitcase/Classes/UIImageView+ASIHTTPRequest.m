//
//  UIImageView+ASIHTTPRequest.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "ASIHTTPRequest.h"
#import <objc/runtime.h>

#import "UIImageView+ASIHTTPRequest.h"

@implementation UIImageView (ASIHTTPRequest)

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url andPlaceholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
    andPlaceholderImage:(UIImage *)placeholderImage
{
    [self setImageWithURL:url andPlaceholderImage:placeholderImage completionBlock:^(UIImage *image) {
        self.image = image;
    }];
}

- (void)setImageWithURL:(NSURL *)url
    andPlaceholderImage:(UIImage *)placeholderImage
        completionBlock:(void (^)(UIImage *))completionBlock
{
    NSURL *currentUrl = objc_getAssociatedObject(self, "url");
    if ([currentUrl isEqual:url]) {
        return;
    }

    if (placeholderImage == nil) {
        self.highlightedImage = nil;
        self.image = nil;
    } else {
        self.image = placeholderImage;
    }

    objc_setAssociatedObject(self, "url", url, OBJC_ASSOCIATION_RETAIN);

    __unsafe_unretained __block ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:url];
    [imageRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [imageRequest setCompletionBlock:^{
        NSData *imageData = [imageRequest responseData];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:imageData];
            completionBlock(image);
        });
    }];

    [imageRequest startAsynchronous];
}

@end
