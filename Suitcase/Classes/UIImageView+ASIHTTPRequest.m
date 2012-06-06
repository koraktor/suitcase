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

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url completionBlock:^(UIImage *image) {
        self.image = image;
    }];
}

- (void)setImageWithURL:(NSURL *)url completionBlock:(void (^)(UIImage *))completionBlock {
    NSURL *currentUrl = objc_getAssociatedObject(self, "url");
    if ([currentUrl isEqual:url]) {
        return;
    }

    self.highlightedImage = nil;
    self.image = nil;

    objc_setAssociatedObject(self, "url", url, OBJC_ASSOCIATION_RETAIN);

    __unsafe_unretained __block ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:url];
    [imageRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [imageRequest setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[imageRequest responseData]];
        completionBlock(image);
    }];

    [imageRequest startAsynchronous];
}

@end
