//
//  UIImageView+ASIHTTPRequest.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface UIImageView (ASIHTTPRequest)

- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url completionBlock:(void (^)(UIImage * image))completionBlock;

@end
