//
//  SCImageCache.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <CommonCrypto/CommonDigest.h>

#import "SCImageCache.h"

@implementation SCImageCache

+ (UIImage *)cachedImageForIdentifier:(NSString *)identifier {
    NSString *path = [self imagePathForIdentifier:identifier];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIScreen *firstScreen = UIScreen.screens[0];
    UIImage *image = [UIImage imageWithData:data scale:firstScreen.scale];

    return image;
}

+ (UIImage *)cachedIconForItem:(id <SCItem>)item {
    return [self cachedImageForIdentifier:[self sha1Identifier:item.iconIdentifier]];
}

+ (UIImage *)cachedImageForItem:(id <SCItem>)item {
    return [self cachedImageForIdentifier:[self sha1Identifier:item.imageIdentifier]];
}

+ (UIImage *)cachedLogoForGame:(SCGame *)game {
    return [self cachedImageForIdentifier:game.logoIdentifier];
}

+ (void)cacheIcon:(UIImage *)icon forItem:(id <SCItem>)item {
    [self cacheImage:icon forIdentifier:[self sha1Identifier:item.iconIdentifier]];
}

+ (void)cacheImage:(UIImage *)image forIdentifier:(NSString *)identifier {
    NSString *path = [self imagePathForIdentifier:identifier];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
}

+ (void)cacheImage:(UIImage *)image forItem:(id <SCItem>)item {
    [self cacheImage:image forIdentifier:[self sha1Identifier:item.imageIdentifier]];
}

+ (void)cacheLogo:(UIImage *)logo forGame:(SCGame *)game {
    [self cacheImage:logo forIdentifier:game.logoIdentifier];
}

+ (void)clearImageCache {
    [self deleteImageCacheDirectory];
    [self setupImageCacheDirectory];
}

+ (void)setupImageCacheDirectory {
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:self.imagesPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];

    if (error != nil) {
        NSLog(@"Image cache directory could not be created: %@", error);
    }
}

+ (void)deleteImageCacheDirectory {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:self.imagesPath error:&error];

    if (error != nil) {
        NSLog(@"Image cache directory could not be deleted: %@", error);
    }
}

+ (NSString *)imagesPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = paths[0];

    return [cachesPath stringByAppendingPathComponent:@"Images"];
}

+ (NSString *)imagePathForIdentifier:(NSString *)identifier {
    NSString *imageName = [NSString stringWithFormat:@"%@.png", identifier];

    return [self.imagesPath stringByAppendingPathComponent:imageName];
}

+ (NSString *)sha1Identifier:(NSString *)identifier {
    NSData *dataToHash = [identifier dataUsingEncoding:NSASCIIStringEncoding];

    unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([dataToHash bytes], (CC_LONG) [dataToHash length], hashBytes);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", hashBytes[i]];
    }

    return [NSString stringWithString:output];
}

@end
