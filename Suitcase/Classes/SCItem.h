//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2014-2016, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCItemSet.h"

#import "SCInventory.h"

@protocol SCItem <NSCoding, NSObject>

@property (nonatomic, strong) id<SCInventory> inventory;
@property (nonatomic, readonly) NSNumber *position;

- (BOOL)belongsToItemSet;
- (NSString *)descriptionText;
- (BOOL)hasOrigin;
- (BOOL)hasQuality;
- (NSString *)iconIdentifier;
- (NSURL *)iconUrl;
- (NSString *)imageIdentifier;
- (NSURL *)imageUrl;
- (BOOL)isKillEater;
- (BOOL)isMarketable;
- (BOOL)isTradable;
- (SCItemSet *)itemSet;
- (NSNumber *)itemCategory;
- (NSNumber *)itemId;
- (NSString *)itemType;
- (NSString *)levelText;
- (NSString *)name;
- (NSString *)origin;
- (NSNumber *)originIndex;
- (NSNumber *)position;
- (UIColor *)qualityColor;
- (NSString *)qualityName;
- (NSNumber *)quantity;
- (NSString *)style;

@end
