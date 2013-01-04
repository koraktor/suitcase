//
//  SCItemImageView.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCItemImageView : UIView

- (UIImageView *)imageView;
- (void)setImageWithURL:(NSURL *)url;

@end
