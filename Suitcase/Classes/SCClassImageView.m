//
//  SCClassImageView.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//


#import <QuartzCore/QuartzCore.h>
#import "UIImageView+ASIHTTPRequest.h"

#import "SCClassImageView.h"

@implementation SCClassImageView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.layer.borderWidth = [[UIScreen mainScreen] scale] * self.layer.frame.size.width / 21;
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
        imageView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        imageView.layer.borderWidth = [[UIScreen mainScreen] scale] * self.layer.frame.size.width / 21;
        imageView.layer.cornerRadius = 5.0;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
    } else {
        imageView = [self.subviews objectAtIndex:0];
    }

    return imageView;
}

- (void)setClassImageWithURL:(NSURL *)url
{
    UIImageView *imageView = self.imageView;

    [imageView setImageWithURL:url completionBlock:^(UIImage *image){
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGRect imageRect = CGRectMake(0, 0, image.size.width * scale, image.size.height * scale);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGContextRef context = CGBitmapContextCreate(nil, image.size.width * scale, image.size.height * scale, 8, 0, colorSpace, kCGImageAlphaNone);
        CGContextDrawImage(context, imageRect, [image CGImage]);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);

        imageView.highlightedImage = image;
        imageView.image = [UIImage imageWithCGImage:imageRef
                                         scale:scale
                                   orientation:UIImageOrientationUp];

        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        CFRelease(imageRef);
    }];
}

- (void)setEquippable:(BOOL)equippable {
    if (equippable) {
        self.alpha = 1.0;
    } else {
        self.alpha = 0.6;
        self.layer.borderColor = [[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8] CGColor];
    }
}

- (void)setEquipped:(BOOL)equipped {
    self.imageView.highlighted = equipped;

    if (equipped) {
        self.layer.borderColor = [[UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:0.8] CGColor];
    } else {
        self.layer.borderColor = [[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8] CGColor];
    }
}

- (void)setHidden:(BOOL)hidden {
    self.imageView.hidden = hidden;

    [super setHidden:hidden];
}

@end
