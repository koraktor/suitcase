//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

#import "SCGame.h"

@class SCInventory;

#import "SCSchema.h"

@interface SCInventory : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSArray *itemSections;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) SCGame *game;
@property (strong, nonatomic) SCSchema *schema;
@property (strong, nonatomic) NSNumber *slots;
@property (nonatomic) BOOL showColors;

+ (void)decreaseInventoriesToLoad;
+ (NSDictionary *)inventories;
+ (NSUInteger)inventoriesToLoad;
+ (AFHTTPRequestOperation *)inventoryForSteamId64:(NSNumber *)steamId64
                                          andGame:(SCGame *)game
                                     andCondition:(NSCondition *)condition;
+ (void)setInventoriesToLoad:(NSUInteger)count;

- (BOOL)isEmpty;
- (BOOL)isSuccessful;
- (void)loadSchema;
- (BOOL)outdated;
- (void)reload;
- (void)sortItems;
- (BOOL)temporaryFailed;

@end
