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

static SCImageCache *_imageCache;

+ (SCImageCache *)imageCache
{
    if (_imageCache == nil) {
        _imageCache = [[SCImageCache alloc] init];
    }

    return _imageCache;
}

- (void)cancelRequest
{
    ASIHTTPRequest *request = objc_getAssociatedObject(self, "request");
    if (request) {
        [request clearDelegatesAndCancel];
    }
}

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url andPlaceholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
    andPlaceholderImage:(UIImage *)placeholderImage
{
    [self setImageWithURL:url
      andPlaceholderImage:placeholderImage
      postprocessingBlock:nil
          completionBlock:^(UIImage *image) {
        self.image = image;
    }];
}

- (void)setImageWithURL:(NSURL *)url
    andPlaceholderImage:(UIImage *)placeholderImage
    postprocessingBlock:(UIImage *(^)(UIImage *))postprocessingBlock
        completionBlock:(void (^)(UIImage *))completionBlock
{
    NSURL *currentUrl = objc_getAssociatedObject(self, "url");
    if ([currentUrl isEqual:url]) {
        return;
    }

    [self cancelRequest];

    UIImage *cachedImage = [[UIImageView imageCache] cachedImageForURL:url];
    if (cachedImage) {
        self.image = cachedImage;
        if (completionBlock != nil) {
            completionBlock(cachedImage);
        }
        return;
    }

    if (placeholderImage == nil) {
        self.highlightedImage = nil;
        self.image = nil;
    } else {
        self.image = placeholderImage;
    }

    objc_setAssociatedObject(self, "url", url, OBJC_ASSOCIATION_RETAIN);

    ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:url];
    __weak ASIHTTPRequest *weakImageRequest = imageRequest;
    [imageRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [imageRequest setCompletionBlock:^{
        NSData *imageData = [weakImageRequest responseData];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:imageData];
            if (postprocessingBlock != nil) {
                image = postprocessingBlock(image);
            }
            [[UIImageView imageCache] cacheImage:image forURL:url];
            if (completionBlock != nil) {
                completionBlock(image);
            }
        });
    }];

    objc_setAssociatedObject(self, "request", imageRequest, OBJC_ASSOCIATION_RETAIN);

    [imageRequest startAsynchronous];
}

@end
