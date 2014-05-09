//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCInventory.h"

@protocol SCItem <NSObject>

@property (readonly) NSNumber *position;

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
- (NSNumber *)position;
- (UIColor *)qualityColor;
- (NSString *)qualityName;
- (NSNumber *)quantity;

@end
