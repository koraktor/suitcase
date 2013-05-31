//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFJSONRequestOperation.h"

#import "SCGame.h"
#import "SCSchema.h"

@interface SCInventory : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSArray *itemSections;
@property (strong, nonatomic) SCGame *game;
@property (strong, nonatomic) SCSchema *schema;
@property (nonatomic) BOOL showColors;

+ (void)decreaseInventoriesToLoad;
+ (NSDictionary *)inventories;
+ (NSUInteger)inventoriesToLoad;
+ (AFJSONRequestOperation *)inventoryForSteamId64:(NSNumber *)steamId64
                                          andGame:(SCGame *)game
                                     andCondition:(NSCondition *)condition;
+ (void)setInventoriesToLoad:(NSUInteger)count;

- (BOOL)isEmpty;
- (BOOL)isSuccessful;
- (void)sortItems;

@end
