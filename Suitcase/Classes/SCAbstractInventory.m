//
//  SCAbstractInventory.m
//  Suitcase
//
//  Copyright (c) 2014-2016, Sebastian Staudt
//

#import "SCAbstractInventory.h"

#import "SCItemCell.h"
#import "SCItemQuality.h"

NSString *const kSCInventoryError = @"kSCInventoryError";

@implementation SCAbstractInventory

static NSArray *__alphabet;
static NSArray *__alphabetWithNumbers;
static SCAbstractInventory *__currentInventory;
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

+ (instancetype)currentInventory {
    return __currentInventory;
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

+ (void)restoreInventories {
    if (__inventories == nil) {
        __inventories = [NSMutableDictionary dictionary];
    }

    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:documentsPath];

    NSString *fileName;
    while (fileName = [dirEnum nextObject]) {
        if ([[fileName pathExtension] isEqualToString:@"inventory"]) {
            id<SCInventory> inventory = [NSKeyedUnarchiver unarchiveObjectWithFile:[documentsPath stringByAppendingPathComponent:fileName]];
            NSNumber *appId = [NSNumber numberWithInteger:[[[fileName lastPathComponent] stringByDeletingPathExtension] integerValue]];
            NSNumber *steamId64 = [NSNumber numberWithInteger:[[fileName stringByDeletingLastPathComponent] integerValue]];
            if (__inventories[steamId64] == nil) {
                __inventories[steamId64] = [NSMutableDictionary dictionary];
            }
            __inventories[steamId64][appId] = inventory;
#ifdef DEBUG
            NSLog(@"Restored inventory for app ID %@ and Steam ID \"%@\".", appId, steamId64);
#endif
        }
    };
}

+ (void)setCurrentInventory:(SCAbstractInventory *)inventory
{
    __currentInventory = inventory;
}

+ (void)storeInventories
{
    [__inventories enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull steamId64, NSDictionary *_Nonnull userInventories, BOOL * _Nonnull stop) {
        [userInventories enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull appId, id<SCInventory> _Nonnull inventory, BOOL * _Nonnull stop) {
            [SCAbstractInventory storeInventory:inventory forAppId:appId andSteamId64:steamId64];
        }];
    }];
}

+ (void)storeInventory:(id<SCInventory>)inventory forAppId:(NSNumber *)appId andSteamId64:(NSNumber *)steamId64 {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *fileName = [NSString stringWithFormat:@"%@.inventory", appId];
    NSString *steamId64Path = [documentsPath stringByAppendingPathComponent:[steamId64 stringValue]];
    NSString *inventoryPath = [steamId64Path stringByAppendingPathComponent:fileName];

    [[NSFileManager defaultManager] createDirectoryAtPath:steamId64Path withIntermediateDirectories:YES attributes:nil error:nil];

    [NSKeyedArchiver archiveRootObject:inventory toFile:inventoryPath];

#ifdef DEBUG
    NSLog(@"Stored inventory for app ID %@ and Steam ID %@.", appId, steamId64);
#endif
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
    return self.state != SCInventoryStateNew && !self.isReloading && !self.isRetrying;
}

- (BOOL)isReloading
{
    return self.state == SCInventoryStateReloading;
}

- (BOOL)isRetrying
{
    return self.state == SCInventoryStateRetrying;
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
    if (self.state == SCInventoryStateSuccessful) {
        self.state = SCInventoryStateReloading;
    } else {
        self.state = SCInventoryStateNew;
    }

    [(id <SCInventory>)self load];
}

- (BOOL)temporaryFailed
{
    return self.state == SCInventoryStateTemporaryFailed;
}

#pragma NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];

    NSNumber *appId = [aDecoder decodeObjectForKey:@"appId"];
    _game = [SCGame gameWithAppId:appId];
    _items = [aDecoder decodeObjectForKey:@"items"];
    _itemQualities = [aDecoder decodeObjectForKey:@"itemQualities"];
    _itemSections = [aDecoder decodeObjectForKey:@"itemSections"];
    _slots = [aDecoder decodeObjectForKey:@"slots"];
    _state = (SCInventoryState) [[aDecoder decodeObjectForKey:@"state"] intValue];
    _steamId64 = [aDecoder decodeObjectForKey:@"steamId64"];
    _timestamp = [aDecoder decodeObjectForKey:@"timestamp"];

    [_items enumerateObjectsUsingBlock:^(id<SCItem> _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        item.inventory = (id<SCInventory>) self;
    }];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_game.appId forKey:@"appId"];
    [aCoder encodeObject:_items forKey:@"items"];
    [aCoder encodeObject:_itemQualities forKey:@"itemQualities"];
    [aCoder encodeObject:_itemSections forKey:@"itemSections"];
    [aCoder encodeObject:_slots forKey:@"slots"];
    [aCoder encodeObject:@(_state) forKey:@"state"];
    [aCoder encodeObject:_steamId64 forKey:@"steamId64"];
    [aCoder encodeObject:_timestamp forKey:@"timestamp"];
}

@end
