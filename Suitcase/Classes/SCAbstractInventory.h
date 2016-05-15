//
//  SCAbstractInventory.h
//  Suitcase
//
//  Copyright (c) 2014-2016, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

#import "SCGame.h"
#import "SCItem.h"

extern NSString *const kSCInventoryError;

@interface SCAbstractInventory : NSObject <NSCoding>

#pragma mark Properties

@property (strong, nonatomic) SCGame *game;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSDictionary *itemQualities;
@property (strong, nonatomic) NSArray *itemSections;
@property (strong, nonatomic) NSArray *loadingItems;
@property (nonatomic) BOOL showColors;
@property (strong, nonatomic) NSNumber *slots;
@property (nonatomic) SCInventoryState state;
@property (strong, nonatomic) NSNumber *steamId64;
@property (strong, nonatomic) NSDate *timestamp;

#pragma mark Class methods

+ (NSArray *)alphabet;
+ (NSArray *)alphabetWithNumbers;
+ (void)addInventory:(SCAbstractInventory *)inventory forUser:(NSNumber *)steamId64 andGame:(SCGame *)game;
+ (instancetype)currentInventory;
+ (NSDictionary *)inventories;
+ (NSDictionary *)inventoriesForUser:(NSNumber *)steamId64;
+ (void)restoreInventories;
+ (void)setCurrentInventory:(SCAbstractInventory *)inventory;
+ (void)storeInventories;

#pragma mark Constructor

- (id)initWithSteamId64:(NSNumber *)steamId64
                andGame:(SCGame *)game;

#pragma mark Instance methods

- (UIColor *)colorForQualityIndex:(NSInteger)index;
- (NSComparisonResult)compare:(id <SCInventory>)inventory;
- (BOOL)failed;
- (void)finish;
- (void)forceOutdated;
- (BOOL)isEmpty;
- (BOOL)isLoaded;
- (BOOL)isReloading;
- (BOOL)isRetrying;
- (BOOL)isSuccessful;
- (BOOL)outdated;
- (void)reload;
- (void)sortItemsByPosition;
- (BOOL)temporaryFailed;

@end
