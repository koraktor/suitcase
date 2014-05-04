//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCGame.h"

@protocol SCInventory <UITableViewDataSource>

@property NSArray *itemSections;
@property BOOL showColors;

+ (instancetype)inventoryForSteamId64:(NSNumber *)steamId64
                              andGame:(SCGame *)game;

- (SCGame *)game;
- (BOOL)isEmpty;
- (BOOL)isSuccessful;
- (NSArray *)items;
- (void)load;
- (void)loadSchema;
- (BOOL)outdated;
- (void)reload;
- (NSNumber *)slots;
- (void)sortItems;
- (NSNumber *)steamId64;
- (BOOL)temporaryFailed;

@end
