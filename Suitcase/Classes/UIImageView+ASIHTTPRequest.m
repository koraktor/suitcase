//
//  UIImageView+ASIHTTPRequest.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "ASIHTTPRequest.h"

#import "UIImageView+ASIHTTPRequest.h"

@implementation UIImageView (ASIHTTPRequest)

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url completionBlock:^(UIImage *image) {
        self.image = image;
    }];
}

- (void)setImageWithURL:(NSURL *)url completionBlock:(void (^)(UIImage *))completionBlock {
    self.highlightedImage = nil;
    self.image = nil;

    __unsafe_unretained __block ASIHTTPRequest *imageRequest = [ASIHTTPRequest requestWithURL:url];
    [imageRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [imageRequest setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[imageRequest responseData]];
        completionBlock(image);
    }];

    [imageRequest startAsynchronous];
}

@end
