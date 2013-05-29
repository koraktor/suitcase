//
//  SCInventory.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "SCAppDelegate.h"
#import "SCInventory.h"
#import "SCItem.h"
#import "SCItemCell.h"

@interface SCInventory () {
    NSArray *_itemTypes;
    NSArray *_items;
    BOOL _successful;
}
@end

@implementation SCInventory

static NSArray *alphabet;
static NSArray *alphabetWithNumbers;
static NSMutableDictionary *__inventories;

@synthesize itemSections = _itemSections;
@synthesize schema = _schema;
@synthesize showColors = _showColors;

+ (NSArray *)alphabet
{
    if (alphabet == nil) {
        alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    }

    return alphabet;
}

+ (NSArray *)alphabetWithNumbers {
    if (alphabetWithNumbers == nil) {
        alphabetWithNumbers = @[@"0–9"];
        alphabetWithNumbers = [alphabetWithNumbers arrayByAddingObjectsFromArray:[SCInventory alphabet]];
    }

    return alphabetWithNumbers;
}

+ (NSDictionary *)inventories
{
    return [__inventories copy];
}

+ (AFJSONRequestOperation *)inventoryForSteamId64:(NSNumber *)steamId64
                                          andGame:(SCGame *)game
{
    if (__inventories == nil) {
        __inventories = [NSMutableDictionary dictionary];
    }

    if ([__inventories objectForKey:steamId64] == nil) {
        [__inventories setObject:[NSMutableDictionary dictionary] forKey:steamId64];
    }
    __block NSMutableDictionary *userInventories = [__inventories objectForKey:steamId64];

    NSDictionary *params = [NSDictionary dictionaryWithObject:steamId64 forKey:@"steamid"];
    AFJSONRequestOperation *inventoryOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:[NSString stringWithFormat:@"IEconItems_%@", game.appId]
                                                                                             andMethod:@"GetPlayerItems"
                                                                                            andVersion:1
                                                                                        withParameters:params];
    [inventoryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *inventoryResponse = [responseObject objectForKey:@"result"];
        SCInventory *inventory;

        if ([[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSArray *itemsResponse = [inventoryResponse objectForKey:@"items"];
            inventory = [[SCInventory alloc] initWithItems:itemsResponse
                                                   andGame:game];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"Error loading the inventory: %@", [inventoryResponse objectForKey:@"statusDetail"]];
            inventory = [[SCInventory alloc] initWithGame:game andErrorMessage:errorMessage];
        }

        [userInventories setObject:inventory forKey:game.appId];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading the inventory: %@", [error localizedDescription]];
        SCInventory *inventory = [[SCInventory alloc] initWithGame:game andErrorMessage:errorMessage];
        [userInventories setObject:inventory forKey:game.appId];
    }];

    return inventoryOperation;
}

- (id)initWithGame:(SCGame *)game
   andErrorMessage:(NSString *)errorMessage
{
    _game = game;
    _successful = NO;

    return self;
}

- (id)initWithItems:(NSArray *)itemsData
            andGame:(SCGame *)game
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[itemsData count]];
    [itemsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [items addObject:[[SCItem alloc] initWithDictionary:obj andInventory:self]];
    }];
    _game = game;
    _items = [items copy];
    _successful = YES;

    NSNumber *showColors = [[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"];
    if (showColors == nil) {
        _showColors = YES;
    } else {
        _showColors = [showColors boolValue];
    }

    return self;
}

- (BOOL)isEmpty
{
    return _items.count == 0;
}

- (BOOL)isSuccessful
{
    return _successful;
}

- (void)sortItems {
    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if (sortOption == nil || [sortOption isEqual:@"position"]) {
        _itemSections = [NSArray arrayWithObject:[_items sortedArrayUsingComparator:^NSComparisonResult(SCItem *item1, SCItem *item2) {
            return [item1.position compare:item2.position];
        }]];
    } else if ([sortOption isEqual:@"name"]) {
        _itemSections = [NSMutableArray arrayWithCapacity:[SCInventory alphabet].count + 1];
        for (NSUInteger i = 0; i <= alphabet.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSString *start = [[item.name substringToIndex:1] uppercaseString];
            NSUInteger nameIndex = [[SCInventory alphabet] indexOfObject:start];
            if (nameIndex == NSNotFound) {
                nameIndex = -1;
            }
            [[_itemSections objectAtIndex:nameIndex + 1] addObject:item];
        }];
    } else if ([sortOption isEqual:@"origin"]) {
        _itemSections = [NSMutableArray arrayWithCapacity:_schema.origins.count];
        for (NSUInteger i = 0; i < _schema.origins.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger originIndex = [[item.dictionary objectForKey:@"origin"] unsignedIntegerValue];
            [[_itemSections objectAtIndex:originIndex] addObject:item];
        }];
    } else if ([sortOption isEqual:@"quality"]) {
        _itemSections = [NSMutableArray arrayWithCapacity:_schema.qualities.count];
        for (NSUInteger i = 0; i < _schema.qualities.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger qualityIndex = [[item.dictionary objectForKey:@"quality"] unsignedIntegerValue];
            [[_itemSections objectAtIndex:qualityIndex] addObject:item];
        }];
    } else if ([sortOption isEqual:@"type"]) {
        if (_itemTypes == nil) {
            _itemTypes = [NSMutableArray array];
            [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
                if (![_itemTypes containsObject:item.itemType]) {
                    [(NSMutableArray *)_itemTypes addObject:item.itemType];
                }
            }];
            _itemTypes = [_itemTypes sortedArrayUsingSelector:@selector(compare:)];
        }

        _itemSections = [NSMutableArray arrayWithCapacity:_itemTypes.count];
        for (NSUInteger i = 0; i < _itemTypes.count; i ++) {
            [(NSMutableArray *)_itemSections addObject:[NSMutableArray array]];
        }
        [_items enumerateObjectsUsingBlock:^(SCItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger typeIndex = [_itemTypes indexOfObject:item.itemType];
            [[_itemSections objectAtIndex:typeIndex] addObject:item];
        }];
    }

    _itemSections = [_itemSections copy];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _itemSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[_itemSections objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCItem *item = [[_itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    SCItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell"];
    cell.item = item;
    cell.showColors = _showColors;
    [cell loadImage];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[_itemSections objectAtIndex:section] count] == 0) {
        return nil;
    }

    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if ([sortOption isEqual:@"name"]) {
        return [[SCInventory alphabetWithNumbers] objectAtIndex:section];
    } else if ([sortOption isEqual:@"origin"]) {
        return NSLocalizedString([_schema originNameForIndex:section], @"Origin name");
    } else if ([sortOption isEqual:@"quality"]) {
        return [_schema qualityNameForIndex:section];
    } else if ([sortOption isEqual:@"type"]) {
        return [_itemTypes objectAtIndex:section];
    } else {
        return nil;
    }
}

@end
