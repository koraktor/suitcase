//
//  SCInventory.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "SCAppDelegate.h"
#import "SCWebApiInventory.h"
#import "SCWebApiItem.h"
#import "SCItemCell.h"

@interface SCWebApiInventory () {
    NSArray *_itemTypes;
    NSNumber *_steamId64;
}
@end

@implementation SCWebApiInventory

static NSArray *alphabet;
static NSArray *alphabetWithNumbers;

+ (AFHTTPRequestOperation *)inventoryOperationForSteamId64:(NSNumber *)steamId64
                                                   andGame:(SCGame *)game
{
    NSDictionary *params = [NSDictionary dictionaryWithObject:steamId64 forKey:@"steamid"];
    return [[SCAppDelegate webApiClient] jsonRequestForInterface:[NSString stringWithFormat:@"IEconItems_%@", game.appId]
                                                       andMethod:@"GetPlayerItems"
                                                      andVersion:1
                                                  withParameters:params
                                                         encoded:NO];
}

+ (instancetype)inventoryForSteamId64:(NSNumber *)steamId64
                                          andGame:(SCGame *)game
{
    NSDictionary *userInventories = [SCAbstractInventory inventoriesForUser:steamId64];
    SCWebApiInventory *inventory = userInventories[game.appId];
    if (inventory != nil) {
        [inventory finish];
        return inventory;
    }

    inventory = [[SCWebApiInventory alloc] initWithSteamId64:steamId64 andGame:game];
    [inventory load];
    [SCAbstractInventory addInventory:inventory forUser:steamId64 andGame:game];

    return inventory;
}

- (void)load
{
    AFHTTPRequestOperation *inventoryOperation = [SCWebApiInventory inventoryOperationForSteamId64:self.steamId64
                                                                                           andGame:self.game];
    [inventoryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *inventoryResponse = [responseObject objectForKey:@"result"];

        if ([[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSArray *itemsData = [inventoryResponse objectForKey:@"items"];
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:[itemsData count]];
            [itemsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [items addObject:[[SCWebApiItem alloc] initWithDictionary:obj
                                                                                    andInventory:self]];
            }];

            self.slots = [inventoryResponse objectForKey:@"num_backpack_slots"];

            self.items = [items copy];
            self.successful = YES;
            self.temporaryFailed = NO;
            self.timestamp = [NSDate date];
        } else {
#ifdef DEBUG
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), [inventoryResponse objectForKey:@"statusDetail"]];
            NSLog(@"Loading inventory for game \"%@\" failed with error: %@", self.game.name, errorMessage);
#endif
            self.successful = NO;
            self.temporaryFailed = NO;
        }

        [self finish];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef DEBUG
        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]];
        NSLog(@"Loading inventory for game \"%@\" failed with error: %@", self.game.name, errorMessage);
#endif

        self.successful = NO;
        self.temporaryFailed = YES;

        [self finish];
    }];

    [inventoryOperation start];
}

- (void)loadSchema
{
    AFHTTPRequestOperation *schemaOperation = [SCWebApiSchema schemaOperationForInventory:self
                                                                        andLanguage:[[NSLocale preferredLanguages] objectAtIndex:0]];
    if (schemaOperation != nil) {
        [schemaOperation start];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaStarted" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished" object:nil];
    }
}

- (void)reload
{
    self.items = [NSArray array];
    [self load];
}

- (void)sortItems {
    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if (sortOption == nil || [sortOption isEqual:@"position"]) {
        self.itemSections = [NSArray arrayWithObject:[self.items sortedArrayUsingComparator:^NSComparisonResult(SCWebApiItem *item1, SCWebApiItem *item2) {
            return [item1.position compare:item2.position];
        }]];
    } else {
        if ([sortOption isEqual:@"name"]) {
            self.itemSections = [NSMutableArray arrayWithCapacity:[SCAbstractInventory alphabet].count + 1];
            for (NSUInteger i = 0; i <= [SCAbstractInventory alphabet].count; i ++) {
                [(NSMutableArray *)self.itemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSString *start = [[item.name substringToIndex:1] uppercaseString];
                NSUInteger nameIndex = [[SCAbstractInventory alphabet] indexOfObject:start];
                if (nameIndex == NSNotFound) {
                    nameIndex = -1;
                }
                [[self.itemSections objectAtIndex:nameIndex + 1] addObject:item];
            }];
        } else if ([sortOption isEqual:@"origin"]) {
            self.itemSections = [NSMutableArray arrayWithCapacity:_schema.origins.count];
            for (NSUInteger i = 0; i < _schema.origins.count; i ++) {
                [(NSMutableArray *)self.itemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSUInteger originIndex = [[item.dictionary objectForKey:@"origin"] unsignedIntegerValue];
                [[self.itemSections objectAtIndex:originIndex] addObject:item];
            }];
        } else if ([sortOption isEqual:@"quality"]) {
            self.itemSections = [NSMutableArray arrayWithCapacity:_schema.qualities.count];
            for (NSUInteger i = 0; i < _schema.qualities.count; i ++) {
                [(NSMutableArray *)self.itemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSUInteger qualityIndex = [[item.dictionary objectForKey:@"quality"] unsignedIntegerValue];
                [[self.itemSections objectAtIndex:qualityIndex] addObject:item];
            }];
        } else if ([sortOption isEqual:@"type"]) {
            if (_itemTypes == nil) {
                _itemTypes = [NSMutableArray array];
                [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                    if (![_itemTypes containsObject:item.itemType]) {
                        [(NSMutableArray *)_itemTypes addObject:item.itemType];
                    }
                }];
                _itemTypes = [_itemTypes sortedArrayUsingSelector:@selector(compare:)];
            }

            self.itemSections = [NSMutableArray arrayWithCapacity:_itemTypes.count];
            for (NSUInteger i = 0; i < _itemTypes.count; i ++) {
                [(NSMutableArray *)self.itemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSUInteger typeIndex = [_itemTypes indexOfObject:item.itemType];
                [[self.itemSections objectAtIndex:typeIndex] addObject:item];
            }];
        }

        NSMutableArray *sortedItemSections = [NSMutableArray arrayWithCapacity:[self.itemSections count]];
        [self.itemSections enumerateObjectsUsingBlock:^(NSArray *section, NSUInteger idx, BOOL *stop) {
            [sortedItemSections addObject:[section sortedArrayUsingComparator:^NSComparisonResult(SCWebApiItem *item1, SCWebApiItem *item2) {
                return [item1.name compare:item2.name];
            }]];
        }];
        self.itemSections = sortedItemSections;
    }

    self.itemSections = [self.itemSections copy];
}

#pragma mark Table View

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.itemSections objectAtIndex:section] count] == 0) {
        return nil;
    }

    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if ([sortOption isEqual:@"name"]) {
        return [[SCAbstractInventory alphabetWithNumbers] objectAtIndex:section];
    } else if ([sortOption isEqual:@"origin"]) {
        return NSLocalizedString([_schema originNameForIndex:section], @"Origin name");
    } else if ([sortOption isEqual:@"quality"]) {
        return [_schema qualityNameForIndex:[NSNumber numberWithInteger:section]];
    } else if ([sortOption isEqual:@"type"]) {
        return [_itemTypes objectAtIndex:section];
    } else {
        return nil;
    }
}

@end
