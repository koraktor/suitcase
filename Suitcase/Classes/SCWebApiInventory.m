//
//  SCInventory.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "SCAppDelegate.h"
#import "SCDota2Item.h"
#import "SCTF2Item.h"
#import "SCWebApiInventory.h"
#import "SCWebApiItem.h"
#import "SCItemCell.h"
#import "SCItemQuality.h"

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
                                                         encoded:NO
                                                   modifiedSince:nil];
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
                SCWebApiItem *item;
                if ([self.game isDota2]) {
                    item = [[SCDota2Item alloc] initWithDictionary:obj andInventory:self];
                } else if ([self.game isTF2]) {
                    item = [[SCTF2Item alloc] initWithDictionary:obj andInventory:self];
                } else {
                    item = [[SCWebApiItem alloc] initWithDictionary:obj andInventory:self];
                }
                [items addObject:item];
            }];

            self.slots = [inventoryResponse objectForKey:@"num_backpack_slots"];

            self.loadingItems = [NSArray arrayWithArray:items];
        } else {
#ifdef DEBUG
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), [inventoryResponse objectForKey:@"statusDetail"]];
            NSLog(@"Loading inventory for game \"%@\" failed with error: %@", self.game.name, errorMessage);
#endif
            self.state = SCInventoryStateFailed;
        }

        [self finish];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef DEBUG
        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]];
        NSLog(@"Loading inventory for game \"%@\" failed with error: %@", self.game.name, errorMessage);
#endif

        self.state = SCInventoryStateTemporaryFailed;

        [self finish];
    }];

    [inventoryOperation start];
}

- (void)loadSchema
{
    AFHTTPRequestOperation *schemaOperation = [SCWebApiSchema schemaOperationForInventory:self
                                                                              andLanguage:SCLanguage.currentLanguage];
    if (schemaOperation != nil) {
        [schemaOperation start];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaStarted" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished" object:nil];
    }
}

- (NSArray *)origins {
    return self.schema.origins;
}

- (NSString *)originNameForIndex:(NSUInteger)index {
    return NSLocalizedString([self.schema originNameForIndex:index], @"Origin name");
}

- (void)setSchema:(SCWebApiSchema *)schema
{
    if (_schema != nil) {
        [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
            [item clearCachedValues];
        }];
    }

    _schema = schema;
}

- (void)sortItems {
    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if (sortOption == nil || [sortOption isEqual:@"position"]) {
        [self sortItemsByPosition];
    } else {
        NSMutableArray *newItemSections;
        if ([sortOption isEqual:@"name"]) {
            newItemSections = [NSMutableArray arrayWithCapacity:[SCAbstractInventory alphabet].count + 1];
            for (NSUInteger i = 0; i <= [SCAbstractInventory alphabet].count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSString *start = [[item.name substringToIndex:1] uppercaseString];
                NSUInteger nameIndex = [[SCAbstractInventory alphabet] indexOfObject:start];
                if (nameIndex == NSNotFound) {
                    nameIndex = -1;
                }
                [newItemSections[nameIndex + 1] addObject:item];
            }];
        } else if ([sortOption isEqual:@"origin"]) {
            newItemSections = [NSMutableArray arrayWithCapacity:_schema.origins.count];
            for (NSUInteger i = 0; i < _schema.origins.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSUInteger originIndex = [[item.dictionary objectForKey:@"origin"] unsignedIntegerValue];
                [newItemSections[originIndex] addObject:item];
            }];
        } else if ([sortOption isEqual:@"quality"]) {
            if (self.itemQualities == nil) {
                NSMutableDictionary *itemQualities = [NSMutableDictionary dictionary];
                [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                    NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                    if ([itemQualities objectForKey:qualityName] == nil) {
                        SCItemQuality *itemQuality = [SCItemQuality itemQualityFromItem:item];
                        itemQualities[itemQuality.name] = itemQuality;
                    }
                }];
                self.itemQualities = [NSDictionary dictionaryWithDictionary:itemQualities];
            }

            newItemSections = [NSMutableArray arrayWithCapacity:self.itemQualities.count];
            for (NSUInteger i = 0; i < self.itemQualities.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                NSUInteger qualityIndex = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] indexOfObject:qualityName];
                [newItemSections[qualityIndex] addObject:item];
            }];
        } else if ([sortOption isEqual:@"type"]) {
            if (_itemTypes == nil) {
                NSMutableArray *itemTypes = [NSMutableArray array];
                [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                    if (![itemTypes containsObject:item.itemType]) {
                        [itemTypes addObject:item.itemType];
                    }
                }];
                _itemTypes = [itemTypes sortedArrayUsingSelector:@selector(compare:)];
            }

            newItemSections = [NSMutableArray arrayWithCapacity:_itemTypes.count];
            for (NSUInteger i = 0; i < _itemTypes.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCWebApiItem *item, NSUInteger idx, BOOL *stop) {
                NSUInteger typeIndex = [_itemTypes indexOfObject:item.itemType];
                [newItemSections[typeIndex] addObject:item];
            }];
        }

        NSMutableArray *sortedItemSections = [NSMutableArray arrayWithCapacity:newItemSections.count];
        [newItemSections enumerateObjectsUsingBlock:^(NSArray *section, NSUInteger idx, BOOL *stop) {
            [sortedItemSections addObject:[section sortedArrayUsingComparator:^NSComparisonResult(SCWebApiItem *item1, SCWebApiItem *item2) {
                return [item1.name compare:item2.name];
            }]];
        }];
        self.itemSections = [NSArray arrayWithArray:sortedItemSections];
    }
}

#pragma NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    _itemTypes = [aDecoder decodeObjectForKey:@"itemTypes"];

    NSString *language = SCLanguage.currentLanguage.localeIdentifier;
    NSString *languageCode = [NSLocale componentsFromLocaleIdentifier:language][(NSString *)kCFLocaleLanguageCode];
    _schema = SCWebApiSchema.schemas[self.game.appId][languageCode];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:(NSCoder *)aCoder];

    [aCoder encodeObject:_itemTypes forKey:@"itemTypes"];
}

@end
