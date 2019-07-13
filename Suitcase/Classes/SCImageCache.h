//
//  SCImageCache.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCGame.h"
#import "SCItem.h"

@interface SCImageCache : NSObject

+ (UIImage *)cachedIconForItem:(id <SCItem>)item;
+ (UIImage *)cachedImageForIdentifier:(NSString *)identifier;
+ (UIImage *)cachedImageForItem:(id <SCItem>)item;
+ (UIImage *)cachedLogoForGame:(SCGame *)game;
+ (void)cacheIcon:(UIImage *)icon forItem:(id <SCItem>)item;
+ (void)cacheImage:(UIImage *)image forIdentifier:(NSString *)identifier;
+ (void)cacheImage:(UIImage *)image forItem:(id <SCItem>)item;
+ (void)cacheLogo:(UIImage *)logo forGame:(SCGame *)game;
+ (void)clearImageCache;
+ (void)deleteImageCacheDirectory;
+ (void)setupImageCacheDirectory;
+ (NSString *)imagePathForIdentifier:(NSString *)identifier;

@end
