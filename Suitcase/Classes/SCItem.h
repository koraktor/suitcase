//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCInventory.h"

@protocol SCItem <NSObject>

- (BOOL)belongsToItemSet;
- (NSString *)descriptionText;
- (BOOL)hasOrigin;
- (BOOL)hasQuality;
- (NSURL *)iconUrl;
- (NSURL *)imageUrl;
- (id<SCInventory>)inventory;
- (BOOL)isKillEater;
- (NSString *)killEaterDescription;
- (NSString *)levelText;
- (NSString *)name;
- (NSString *)origin;
- (UIColor *)qualityColor;
- (NSString *)qualityName;
- (NSNumber *)quantity;

@end
