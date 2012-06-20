//
//  SCImageCache.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCImageCache.h"

@implementation SCImageCache

+ (NSString *)keyForURL:(NSURL *)url
{
    return [url absoluteString];
}

- (UIImage *)cachedImageForURL:(NSURL *)url
{
    return [self objectForKey:[SCImageCache keyForURL:url]];
}

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url
{
    [self setObject:image forKey:[SCImageCache keyForURL:url]];
}

@end
