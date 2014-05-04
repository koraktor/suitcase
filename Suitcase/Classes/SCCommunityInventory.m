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
    self.items = [NSArray array];

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

    self.items = [self.items arrayByAddingObjectsFromArray:newItems];
}

- (void)failedTemporary:(BOOL)temporaryFailed
            forItemType:(NSNumber *)itemType
       withErrorMessage:(NSString *)errorMessage
{
    self.temporaryFailed = temporaryFailed;

#ifdef DEBUG
    NSLog(@"Loading inventory for game \"%@\" (item type %@) failed with error: %@", self.game.name, itemType, errorMessage);
#endif
}

- (void)load
{
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (NSNumber *itemCategory in self.game.itemCategories) {
        dispatch_group_enter(dispatchGroup);
        AFHTTPRequestOperation *itemCategoryOperation = [SCCommunityInventory inventoryOperationForSteamId64:self.steamId64
                                                                                                     andGame:self.game
                                                                                             andItemCategory:itemCategory];
        [itemCategoryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject[@"success"] isEqualToNumber:@1] && [responseObject[@"rgInventory"] isKindOfClass:[NSDictionary class]]) {
                [self addItems:[responseObject[@"rgInventory"] allValues] withDescriptions:responseObject[@"rgDescriptions"] andItemCategory:itemCategory];
            } else {
                if (![self temporaryFailed]) {
                    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), @""];
                    [self failedTemporary:NO forItemType:itemCategory withErrorMessage:errorMessage];
                }
            }

            dispatch_group_leave(dispatchGroup);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (![self temporaryFailed]) {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCInventoryError, kSCInventoryError), [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]];
                [self failedTemporary:YES forItemType:itemCategory withErrorMessage:errorMessage];
            }

            dispatch_group_leave(dispatchGroup);
        }];

        [itemCategoryOperation start];
    }

    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);

    self.timestamp = [NSDate date];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self finish];
    });
}

- (void)loadSchema {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished" object:nil];
}

- (void)reload
{
    self.items = [NSArray array];
    _descriptions = [NSArray array];
    _itemTypes = nil;
    [self load];
}

- (void)sortItems
{
    NSString *sortOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if (sortOption == nil || !([sortOption isEqual:@"name"] || [sortOption isEqual:@"type"])) {
        self.itemSections = [NSArray arrayWithObject:[self.items sortedArrayUsingComparator:^NSComparisonResult(SCCommunityItem *item1, SCCommunityItem *item2) {
            return [item1.position compare:item2.position];
        }]];
    } else if ([sortOption isEqual:@"name"]) {
        self.itemSections = [NSMutableArray arrayWithCapacity:[SCAbstractInventory alphabet].count + 1];
        for (NSUInteger i = 0; i <= [SCAbstractInventory alphabet].count; i ++) {
            [(NSMutableArray *)self.itemSections addObject:[NSMutableArray array]];
        }
        [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
            NSString *start = [[item.name substringToIndex:1] uppercaseString];
            NSUInteger nameIndex = [[SCAbstractInventory alphabet] indexOfObject:start];
            if (nameIndex == NSNotFound) {
                nameIndex = -1;
            }
            [[self.itemSections objectAtIndex:nameIndex + 1] addObject:item];
        }];
    } else if ([sortOption isEqual:@"type"]) {
        if (_itemTypes == nil) {
            _itemTypes = [NSMutableArray array];
            [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
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
        [self.items enumerateObjectsUsingBlock:^(SCCommunityItem *item, NSUInteger idx, BOOL *stop) {
            NSUInteger typeIndex = [_itemTypes indexOfObject:item.itemType];
            [[self.itemSections objectAtIndex:typeIndex] addObject:item];
        }];
    }
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
    } else if ([sortOption isEqual:@"type"]) {
        return [_itemTypes objectAtIndex:section];
    } else {
        return nil;
    }
}

@end
