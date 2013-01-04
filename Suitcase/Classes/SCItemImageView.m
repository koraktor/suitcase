//
//  SCItemImageView.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>
#import "UIImageView+ASIHTTPRequest.h"

#import "SCItemImageView.h"

@implementation SCItemImageView

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

    if ([self.subviews count] == 0) {
        CGRect rect = CGRectInset(self.bounds, 0.0, 0.0);
        imageView = [[UIImageView alloc] initWithFrame:rect];
        imageView.layer.cornerRadius = 5.0;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
    } else {
        imageView = [self.subviews objectAtIndex:0];
    }

    return imageView;
}

- (void)setImageWithURL:(NSURL *)url
{
    UIImageView *imageView = self.imageView;

    [imageView setImageWithURL:url
           andPlaceholderImage:nil
           postprocessingBlock:nil
               completionBlock:^(UIImage *image){
                   imageView.image = image;
               }];
}

@end
