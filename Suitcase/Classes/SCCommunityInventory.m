//
//  SCCommunityInventory.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//
//

#import "SCAppDelegate.h"
#import "SCCommunityInventory.h"
#import "SCCommunityItem.h"
#import "SCItemCell.h"
#import "SCItemQuality.h"

@interface SCCommunityInventory() {
    NSArray *_descriptions;
    NSArray *_itemTypes;
}
@end

@implementation SCCommunityInventory

+ (instancetype)inventoryForSteamId64:(NSNumber *)steamId64
                              andGame:(SCGame *)game
{
    NSDictionary *userInventories = [SCAbstractInventory inventoriesForUser:steamId64];
    SCCommunityInventory *inventory = userInventories[game.appId];
    if (inventory != nil) {
        [inventory finish];
        return inventory;
    }

    inventory = [[SCCommunityInventory alloc] initWithSteamId64:steamId64 andGame:game];
    [NSThread detachNewThreadSelector:@selector(load) toTarget:inventory withObject:nil];
    [SCAbstractInventory addInventory:inventory forUser:steamId64 andGame:game];

#ifdef DEBUG
    NSLog(@"Inventory for %@ created.", game.name);
#endif

    return inventory;
}

+ (AFHTTPRequestOperation *)inventoryOperationForSteamId64:(NSNumber *)steamId64
                                                   andGame:(SCGame *)game
                                           andItemCategory:(NSNumber *)itemCategory
{
    return [[SCAppDelegate communityClient] jsonRequestForSteamId64:steamId64
                                                            andGame:game
                                                    andItemCategory:itemCategory];
}

- (id)initWithSteamId64:(NSNumber *)steamId64
                andGame:(SCGame *)game
{
    self = [super initWithSteamId64:steamId64 andGame:game];

    _descriptions = [NSArray array];

    return self;
}

- (void)addItems:(NSArray *)items
withDescriptions:(NSDictionary *)descriptions
 andItemCategory:(NSNumber *)itemCategory
{
    NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:items.count];
    for (NSDictionary *rawItem in items) {
        NSNumber *classId = rawItem[@"classid"];
        NSNumber *instanceId = rawItem[@"instanceid"];
        NSDictionary *description = [descriptions objectForKey:[NSString stringWithFormat:@"%@_%@", classId, instanceId]];
        NSMutableDictionary *itemData = [NSMutableDictionary dictionaryWithDictionary:description];
        [itemData addEntriesFromDictionary:rawItem];
        SCCommunityItem *item = [[SCCommunityItem alloc] initWithDictionary:[itemData copy]
                                                               andInventory:self
                                                            andItemCategory:itemCategory];
        [newItems addObject:item];
    }

    self.loadingItems = [self.loadingItems arrayByAddingObjectsFromArray:newItems];
}

- (void)failedTemporary:(BOOL)temporaryFailed
            forItemType:(NSNumber *)itemType
       withErrorMessage:(NSString *)errorMessage
{
    if (temporaryFailed) {
        self.state = SCInventoryStateTemporaryFailed;
    } else {
        self.state = SCInventoryStateFailed;
    }

#ifdef DEBUG
    NSLog(@"Loading inventory for game \"%@\" (item type %@) failed with error: %@", self.game.name, itemType, errorMessage);
#endif
}

- (void)load
{
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (NSNumber *itemCategory in self.game.itemCategories) {
        dispatch_group_enter(dispatchGroup);

        AFHTTPRequestOperation *itemCategoryOperation = [self operationForItemCategory:itemCategory
                                                                       inDispatchGroup:dispatchGroup
                                                                        withRetryDelay:0];

        [itemCategoryOperation start];
    }

    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self finish];
    });
}

- (void)loadSchema {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished" object:nil];
}

- (NSArray *)origins {
    return nil;
}

- (AFHTTPRequestOperation *)operationForItemCategory:(NSNumber *)itemCategory
                                     inDispatchGroup:(dispatch_group_t)dispatchGroup
                                      withRetryDelay:(NSUInteger)retryDelay {
    AFHTTPRequestOperation *itemCategoryOperation = [SCCommunityInventory inventoryOperationForSteamId64:self.steamId64
                                                                                              andGame:self.game
                                                                                      andItemCategory:itemCategory];
    [itemCategoryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (![self temporaryFailed]) {
            if ([responseObject[@"success"] isEqualToNumber:@1]) {
                if ([responseObject[@"rgInventory"] isKindOfClass:[NSDictionary class]]) {
                    [self addItems:[responseObject[@"rgInventory"] allValues]
                  withDescriptions:responseObject[@"rgDescriptions"]
                   andItemCategory:itemCategory];
                }
            } else {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), responseObject[@"Error"]];
                [self failedTemporary:NO forItemType:itemCategory withErrorMessage:errorMessage];
            }
        }

        dispatch_group_leave(dispatchGroup);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        BOOL finished = YES;
        BOOL failed = YES;
        if (operation.response.statusCode == 429) {
#ifdef DEBUG
            NSLog(@"Too many requests.");
#endif
            if (self.isReloading) {
#ifdef DEBUG
                NSLog(@"  Inventory is reloading. Ignoring failure.");
#endif
                self.loadingItems = self.items;
            } else {
#ifdef DEBUG
                NSLog(@"  Retrying…");
#endif

                uint64_t delay = ((1 << retryDelay) - 1) * NSEC_PER_SEC;
                dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delay);
                if (retryDelay < 4) {
                    failed = NO;
                    finished = NO;
                    dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        AFHTTPRequestOperation *retryOperation = [self operationForItemCategory:itemCategory
                                                                                inDispatchGroup:dispatchGroup
                                                                                 withRetryDelay:retryDelay + 1];
                        [retryOperation start];
                    });
                }
            }
        } else if (self.isReloading && [operation.responseString isEqualToString:@"null"]) {
            failed = NO;
            self.loadingItems = self.items;
#ifdef DEBUG
            NSLog(@"Silently ignore load failure.");
#endif
        }

        if (finished) {
            if (failed) {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]];
                [self failedTemporary:YES forItemType:itemCategory withErrorMessage:errorMessage];
            }

            dispatch_group_leave(dispatchGroup);
        }
    }];

    return itemCategoryOperation;
}

- (NSString *)originNameForIndex:(NSUInteger)index {
    return nil;
}

- (void)reload
{
    _descriptions = [NSArray array];
    _itemTypes = nil;

    [super reload];
}

- (void)sortItems
{
    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if (sortOption == nil || [sortOption isEqualToString:@"origin"] || [sortOption isEqualToString:@"position"]) {
        [self sortItemsByPosition];
    } else {
        NSMutableArray *newItemSections;
        if ([sortOption isEqualToString:@"name"]) {
            newItemSections = [NSMutableArray arrayWithCapacity:[SCAbstractInventory alphabet].count + 1];
            for (NSUInteger i = 0; i <= [SCAbstractInventory alphabet].count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
                NSString *start = [[item.name substringToIndex:1] uppercaseString];
                NSUInteger nameIndex = [[SCAbstractInventory alphabet] indexOfObject:start];
                if (nameIndex == NSNotFound) {
                    nameIndex = -1;
                }
                [newItemSections[nameIndex + 1] addObject:item];
            }];
        } else if ([sortOption isEqualToString:@"quality"]) {
            if (self.itemQualities == nil) {
                NSMutableDictionary *itemQualities = [NSMutableDictionary dictionary];
                [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
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
            [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
                NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                NSUInteger qualityIndex = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] indexOfObject:qualityName];
                [newItemSections[qualityIndex] addObject:item];
            }];
        } else if ([sortOption isEqualToString:@"type"]) {
            if (_itemTypes == nil) {
                NSMutableArray *itemTypes = [NSMutableArray array];
                [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
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
            [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
                NSUInteger typeIndex = [_itemTypes indexOfObject:item.itemType];
                [newItemSections[typeIndex] addObject:item];
            }];
        }

        NSMutableArray *sortedItemSections = [NSMutableArray arrayWithCapacity:newItemSections.count];
        [newItemSections enumerateObjectsUsingBlock:^(NSArray *section, NSUInteger idx, BOOL *stop) {
            [sortedItemSections addObject:[section sortedArrayUsingComparator:^NSComparisonResult(SCCommunityItem *item1, SCCommunityItem *item2) {
                return [item1.name compare:item2.name];
            }]];
        }];
        self.itemSections = [NSArray arrayWithArray:sortedItemSections];
    }
}

@end
