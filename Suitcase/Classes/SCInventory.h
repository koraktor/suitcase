//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCGame.h"

typedef NS_ENUM(NSUInteger, SCInventoryState) {
    SCInventoryStateNew,
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
- (BOOL)failed;
- (SCGame *)game;
- (BOOL)isEmpty;
- (BOOL)isLoaded;
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
