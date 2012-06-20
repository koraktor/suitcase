//
//  SCImageCache.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

@interface SCImageCache : NSCache

+ (NSString *)keyForURL:(NSURL *)url;

- (UIImage *)cachedImageForURL:(NSURL *)url;
- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url;

@end
