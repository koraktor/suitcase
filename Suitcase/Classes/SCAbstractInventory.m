//
//  SCAbstractInventory.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
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
    self.slots = @0;
    self.steamId64 = steamId64;
    self.successful = NO;
    self.temporaryFailed = NO;

    return self;
}

#pragma mark Instance methods

- (UIColor *)colorForQualityIndex:(NSInteger)index
{
    NSString *qualityName = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:index];

    return ((SCItemQuality *)self.itemQualities[qualityName]).color;
}

- (void)finish
{
    if (!self.temporaryFailed) {
        self.successful = YES;
    }
    self.timestamp = [NSDate date];

    NSNumber *showColors = [[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"];
    self.showColors = (showColors == nil) ? YES : [showColors boolValue];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"inventoryLoaded" object:self];

#ifdef DEBUG
    NSLog(@"Loading inventory for game \"%@\" finished.", self.game.name);
#endif
}

- (BOOL)isLoaded
{
    return self.timestamp != nil;
}

- (void)sortItemsByPosition
{
    self.itemSections = [NSArray arrayWithObject:[self.items sortedArrayUsingComparator:^NSComparisonResult(id <SCItem> item1, id <SCItem> item2) {
        return [item1.position compare:item2.position];
    }]];
}

- (BOOL)isEmpty
{
    return self.successful && _items.count == 0;
}

- (BOOL)outdated
{
    return [_timestamp timeIntervalSinceNow] < -600;
}

@end
