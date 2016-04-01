//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2014-2016, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCGame.h"

typedef NS_ENUM(NSUInteger, SCInventoryState) {
    SCInventoryStateNew,
    SCInventoryStateReloading,
    SCInventoryStateRetrying,
    SCInventoryStateSuccessful,
    SCInventoryStateTemporaryFailed,
    SCInventoryStateFailed
};

@protocol SCInventory <NSObject>

@property NSArray *itemSections;
@property BOOL showColors;

+ (instancetype)inventoryForSteamId64:(NSNumber *)steamId64
                              andGame:(SCGame *)game;

- (UIColor *)colorForQualityIndex:(NSInteger)index;
- (NSComparisonResult)compare:(id <SCInventory>)inventory;
- (BOOL)failed;
- (SCGame *)game;
- (BOOL)isEmpty;
- (BOOL)isLoaded;
- (BOOL)isReloading;
- (BOOL)isRetrying;
- (BOOL)isSuccessful;
- (NSArray *)items;
- (void)load;
- (void)loadSchema;
- (NSArray *)origins;
- (NSString *)originNameForIndex:(NSUInteger)index;
- (BOOL)outdated;
- (void)reload;
- (NSNumber *)slots;
- (NSNumber *)steamId64;
- (BOOL)temporaryFailed;

@end
