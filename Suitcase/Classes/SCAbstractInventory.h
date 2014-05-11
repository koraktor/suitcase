//
//  SCAbstractInventory.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

#import "SCGame.h"
#import "SCItem.h"

extern NSString *const kSCInventoryError;

@interface SCAbstractInventory : NSObject

#pragma mark Properties

@property (strong, nonatomic) SCGame *game;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSDictionary *itemQualities;
@property (strong, nonatomic) NSArray *itemSections;
@property (nonatomic) BOOL showColors;
@property (strong, nonatomic) NSNumber *slots;
@property (strong, nonatomic) NSNumber *steamId64;
@property (nonatomic, getter = isSuccessful) BOOL successful;
@property (nonatomic) BOOL temporaryFailed;
@property (strong, nonatomic) NSDate *timestamp;

#pragma mark Class methods

+ (NSArray *)alphabet;
+ (NSArray *)alphabetWithNumbers;
+ (void)addInventory:(SCAbstractInventory *)inventory forUser:(NSNumber *)steamId64 andGame:(SCGame *)game;
+ (NSDictionary *)inventories;
+ (NSDictionary *)inventoriesForUser:(NSNumber *)steamId64;

#pragma mark Constructor

- (id)initWithSteamId64:(NSNumber *)steamId64
                andGame:(SCGame *)game;

#pragma mark Instance methods

- (UIColor *)colorForQualityIndex:(NSInteger)index;
- (void)finish;
- (BOOL)isEmpty;
- (BOOL)isLoaded;
- (BOOL)outdated;
- (void)sortItemsByPosition;

@end
