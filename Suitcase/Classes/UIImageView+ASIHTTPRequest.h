//
//  UIImageView+ASIHTTPRequest.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCImageCache.h"

@interface UIImageView (ASIHTTPRequest)

+ (SCImageCache *)imageCache;

- (void)cancelRequest;
- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder;
- (void)setImageWithURL:(NSURL *)url
    andPlaceholderImage:(UIImage *)placeholderImage
        completionBlock:(void (^)(UIImage * image))completionBlock;

@end
