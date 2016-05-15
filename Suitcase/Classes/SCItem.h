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

@property (nonatomic, readonly) NSNumber *position;

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
- (BOOL)isMarketable;
- (BOOL)isTradable;
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
- (NSString *)style;

@end
