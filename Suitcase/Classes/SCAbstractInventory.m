//
//  SCAbstractInventory.m
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import "SCAbstractInventory.h"

#import "SCItemCell.h"
#import "SCItemQuality.h"

NSString *const kSCInventoryError = @"kSCInventoryError";

@implementation SCAbstractInventory

static NSArray *__alphabet;
static NSArray *__alphabetWithNumbers;
static NSMutableDictionary *__inventories;

#pragma mark Class methods

+ (NSArray *)alphabet
{
    if (__alphabet == nil) {
        __alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    }

    return __alphabet;
}

+ (NSArray *)alphabetWithNumbers {
    if (__alphabetWithNumbers == nil) {
        __alphabetWithNumbers = @[@"0–9"];
        __alphabetWithNumbers = [__alphabetWithNumbers arrayByAddingObjectsFromArray:[SCAbstractInventory alphabet]];
    }

    return __alphabetWithNumbers;
}

+ (void)addInventory:(SCAbstractInventory *)inventory forUser:(NSNumber *)steamId64 andGame:(SCGame *)game
{
    __inventories[steamId64][game.appId] = inventory;
}

+ (NSDictionary *)inventories
{
    return __inventories;
}

+ (NSDictionary *)inventoriesForUser:(NSNumber *)steamId64
{
    if (__inventories == nil) {
        __inventories = [NSMutableDictionary dictionary];
    }

    if (__inventories[steamId64] == nil) {
        __inventories[steamId64] = [NSMutableDictionary dictionary];
    }

    return __inventories[steamId64];
}

#pragma mark Constructor

- (id)initWithSteamId64:(NSNumber *)steamId64
                andGame:(SCGame *)game
{
    self.game = game;
    self.items = @[];
    self.loadingItems = @[];
    self.slots = @0;
    self.state = SCInventoryStateNew;
    self.steamId64 = steamId64;

    return self;
}

#pragma mark Instance methods

- (UIColor *)colorForQualityIndex:(NSInteger)index
{
    NSString *qualityName = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:index];

    return ((SCItemQuality *)self.itemQualities[qualityName]).color;
}

- (NSComparisonResult)compare:(id <SCInventory>)inventory {
    return [self.game compare:inventory.game];
}

- (BOOL)failed
{
    return self.state == SCInventoryStateFailed;
}

- (void)finish
{
    if (self.state == SCInventoryStateNew || self.isReloading) {
        self.items = self.loadingItems;
        self.state = SCInventoryStateSuccessful;
    }
    self.timestamp = [NSDate date];

    NSNumber *showColors = [[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"];
    self.showColors = (showColors == nil) ? YES : [showColors boolValue];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"inventoryLoaded" object:self];
    });
}

- (void)forceOutdated
{
    self.timestamp = [NSDate dateWithTimeIntervalSince1970:0];
}

- (NSUInteger)hash
{
    return [self.game hash] ^ [self.steamId64 hash];
}

- (BOOL)isEqual:(id)object
{
    if (![[object class] conformsToProtocol:@protocol(SCInventory)]) {
        return NO;
    }

    id <SCInventory> other = object;

    return [self.game isEqual:other.game] && [self.steamId64 isEqual:other.steamId64];
}

- (BOOL)isLoaded
{
    return self.state != SCInventoryStateNew && !self.isReloading;
}

- (BOOL)isReloading
{
    return self.state == SCInventoryStateReloading;
}

- (BOOL)isSuccessful
{
    return self.state == SCInventoryStateSuccessful;
}

- (void)sortItemsByPosition
{
    self.itemSections = [NSArray arrayWithObject:[self.items sortedArrayUsingComparator:^NSComparisonResult(id <SCItem> item1, id <SCItem> item2) {
        return [item1.position compare:item2.position];
    }]];
}

- (BOOL)isEmpty
{
    return [self isSuccessful] && _items.count == 0;
}

- (BOOL)outdated
{
    return [_timestamp timeIntervalSinceNow] < -600;
}

- (void)reload
{
    self.loadingItems = @[];
    self.state = SCInventoryStateReloading;

    [(id <SCInventory>)self load];
}

- (BOOL)temporaryFailed
{
    return self.state == SCInventoryStateTemporaryFailed;
}

@end
