//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCItemSet.h"

#import "SCInventory.h"

@protocol SCItem <NSObject>

@property (readonly) NSNumber *position;

- (BOOL)belongsToItemSet;
- (NSString *)descriptionText;
- (BOOL)hasOrigin;
- (BOOL)hasQuality;
- (NSString *)iconIdentifier;
- (NSURL *)iconUrl;
- (NSString *)imageIdentifier;
- (NSURL *)imageUrl;
- (id<SCInventory>)inventory;
- (BOOL)isKillEater;
- (SCItemSet *)itemSet;
- (NSString *)itemType;
- (NSString *)levelText;
- (NSString *)name;
- (NSString *)origin;
- (NSNumber *)originIndex;
- (NSNumber *)position;
- (UIColor *)qualityColor;
- (NSString *)qualityName;
- (NSNumber *)quantity;

@end
