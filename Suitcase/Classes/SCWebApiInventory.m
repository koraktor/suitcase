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
#import "SCItemQuality.h"

@interface SCWebApiInventory () {
    NSArray *_itemTypes;
}
@end

@implementation SCWebApiInventory

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
            for (NSDictionary *itemData in itemsData) {
                SCWebApiItem *item;
                if ([self.game isDota2]) {
                    item = [[SCDota2Item alloc] initWithDictionary:itemData andInventory:self];
                } else if ([self.game isTF2]) {
                    item = [[SCTF2Item alloc] initWithDictionary:itemData andInventory:self];
                } else {
                    item = [[SCWebApiItem alloc] initWithDictionary:itemData andInventory:self];
                }
                [items addObject:item];
            };

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
        for (SCWebApiItem *item in self.items) {
            [item clearCachedValues];
        };
    }

    _schema = schema;
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
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_itemTypes forKey:@"itemTypes"];
}

@end
