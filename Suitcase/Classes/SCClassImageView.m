//
//  SCClassImageView.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//


#import <QuartzCore/QuartzCore.h>
#import "AFHTTPRequestOperation.h"
#import "UIImageView+AFNetworking.h"

#import "SCClassImageView.h"

@implementation SCClassImageView

- (void)setClassImageWithURL:(NSURL *)url
{
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.layer.borderWidth = [[UIScreen mainScreen] scale] * self.layer.frame.size.width / 21;
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];

    [self setImageWithURLRequest:request
                placeholderImage:nil
                         success:^(NSURLRequest *request, NSURLResponse *response, UIImage *image) {
                             CGFloat scale = [[UIScreen mainScreen] scale];
                             CGRect imageRect = CGRectMake(0, 0, image.size.width * scale, image.size.height * scale);
                             CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
                             CGContextRef context = CGBitmapContextCreate(nil, image.size.width * scale, image.size.height * scale, 8, 0, colorSpace, kCGImageAlphaNone);
                             CGContextDrawImage(context, imageRect, [image CGImage]);
                             CGImageRef imageRef = CGBitmapContextCreateImage(context);

                             self.highlightedImage = image;
                             self.image = [UIImage imageWithCGImage:imageRef
                                                              scale:scale
                                                        orientation:UIImageOrientationUp];

                             CGColorSpaceRelease(colorSpace);
                             CGContextRelease(context);
                             CFRelease(imageRef);
                         } failure:nil];
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
    self.highlighted = equipped;

    if (equipped) {
        self.layer.borderColor = [[UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:0.8] CGColor];
    } else {
        self.layer.borderColor = [[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8] CGColor];
    }
}

@end
