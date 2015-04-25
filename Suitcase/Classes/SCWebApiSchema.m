//
//  SCSchema.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import "SCAppDelegate.h"
#import "SCWebApiInventory.h"
#import "SCWebApiSchema.h"

@implementation SCWebApiSchema

static NSMutableDictionary *__schemas;

+ (NSDictionary *)schemas
{
    return [__schemas copy];
}

+ (AFHTTPRequestOperation *)schemaOperationForInventory:(SCWebApiInventory *)inventory
                                            andLanguage:(NSLocale *)locale
{
    NSString *language = locale.localeIdentifier;

    if (__schemas == nil) {
        __schemas = [NSMutableDictionary dictionary];
    }

    NSNumber *appId = inventory.game.appId;

    if ([__schemas objectForKey:appId] == nil) {
        [__schemas setObject:[NSMutableDictionary dictionary] forKey:appId];
    } else {
        SCWebApiSchema *schema = [[__schemas objectForKey:appId] objectForKey:language];
        if (schema != nil) {
            inventory.schema = schema;
            return nil;
        }
    }
    __block NSMutableDictionary *gameSchemas = [__schemas objectForKey:appId];

    int version = 1;
    if ([appId isEqualToNumber:@730]) {
        version = 2;
    }

    NSDictionary *params = [NSDictionary dictionaryWithObject:language forKey:@"language"];
    AFHTTPRequestOperation *schemaOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:[NSString stringWithFormat:@"IEconItems_%@", appId]
                                                                                          andMethod:@"GetSchema"
                                                                                         andVersion:version
                                                                                     withParameters:params
                                                                                            encoded:NO];
    ((NSMutableURLRequest *)schemaOperation.request).timeoutInterval = 60;
    [schemaOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
#ifdef DEBUG
        NSLog(@"Finished loading item schema for %@", appId);
#endif
        NSDictionary *schemaResponse = [responseObject objectForKey:@"result"];

        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            SCWebApiSchema *schema = [[SCWebApiSchema alloc] initWithDictionary:schemaResponse];
            [gameSchemas setObject:schema forKey:language];
            inventory.schema = schema;

            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished" object:nil];
        } else {
            inventory.schema = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished"
                                                                object:[schemaResponse objectForKey:@"statusDetail"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        inventory.schema = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished"
                                                            object:[error localizedDescription]];
    }];

    return schemaOperation;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    NSArray *attributesArray = [dictionary objectForKey:@"attributes"];
    _attributes = [NSMutableDictionary dictionaryWithCapacity:[attributesArray count]];
    [attributesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.attributes setValue:obj forKey:[obj objectForKey:@"defindex"]];
        [self.attributes setValue:obj forKey:[obj objectForKey:@"name"]];
    }];
    _attributes = [_attributes copy];

    NSArray *effectsArray = [dictionary objectForKey:@"attribute_controlled_attached_particles"];
    _effects = [NSMutableDictionary dictionaryWithCapacity:[effectsArray count]];
    [effectsArray enumerateObjectsUsingBlock:^(NSDictionary *effect, NSUInteger idx, BOOL *stop) {
        [(NSMutableDictionary *)_effects setObject:[effect objectForKey:@"name"]
                                            forKey:[effect objectForKey:@"id"]];
    }];
    _effects = [_effects copy];

    NSArray *itemsArray = [dictionary objectForKey:@"items"];
    _items = [NSMutableDictionary dictionaryWithCapacity:[itemsArray count]];
    _itemNameMap = [NSMutableDictionary dictionaryWithCapacity:[itemsArray count]];
    [itemsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.items setValue:obj forKey:[obj objectForKey:@"defindex"]];
        [self.itemNameMap setValue:[obj objectForKey:@"defindex"] forKey:[obj objectForKey:@"name"]];
    }];
    _items = [_items copy];
    _itemNameMap = [_itemNameMap copy];

    NSArray *itemLevels = [dictionary objectForKey:@"item_levels"];
    _itemLevels = [NSMutableDictionary dictionaryWithCapacity:[itemLevels count]];
    [itemLevels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(NSMutableDictionary *)_itemLevels setObject:[obj objectForKey:@"levels"]
                                                   forKey:[obj objectForKey:@"name"]];
    }];
    _itemLevels = [_itemLevels copy];

    NSArray *itemSets = [dictionary objectForKey:@"item_sets"];
    _itemSets = [NSMutableDictionary dictionaryWithCapacity:[itemSets count]];
    [itemSets enumerateObjectsUsingBlock:^(id itemSet, NSUInteger idx, BOOL *stop) {
        [(NSMutableDictionary *)_itemSets setObject:itemSet
                                             forKey:[itemSet objectForKey:@"item_set"]];
    }];
    _itemSets = [_itemSets copy];

    NSArray *killEaterTypes = [dictionary objectForKey:@"kill_eater_score_types"];
    _killEaterTypes = [NSMutableDictionary dictionaryWithCapacity:[killEaterTypes count]];
    [killEaterTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(NSMutableDictionary *)_killEaterTypes setObject:obj
                                                   forKey:[obj objectForKey:@"type"]];
    }];
    _killEaterTypes = [_killEaterTypes copy];

    NSArray *originsArray = [dictionary objectForKey:@"originNames"];
    _origins = [NSMutableArray arrayWithCapacity:[originsArray count]];
    [originsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *index = [obj objectForKey:@"origin"];
        [(NSMutableArray *)self.origins insertObject:[obj objectForKey:@"name"] atIndex:[index unsignedIntValue]];
    }];
    _origins = [_origins copy];

    NSDictionary *qualityKeys = [dictionary objectForKey:@"qualities"];
    NSDictionary *qualityNames = [dictionary objectForKey:@"qualityNames"];
    _qualities = [NSMutableArray arrayWithCapacity:[qualityKeys count]];
    for (int i = 0; i < [qualityKeys count]; i ++) {
        [(NSMutableArray *)_qualities addObject:[NSNull null]];
    }
    [qualityKeys enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *index, BOOL *stop) {
        NSString *qualityName = [qualityNames objectForKey:key];
        if (qualityName == nil) {
            qualityName = [key capitalizedString];
        }
        [(NSMutableArray *)self.qualities replaceObjectAtIndex:[index integerValue]
                                                    withObject:qualityName];
    }];
    _qualities = [_qualities copy];

#ifdef DEBUG
    NSLog(@"Finished initializing item schema.");
#endif

    return self;
}

- (id)attributeValueFor:(id)attributeKey andKey:(NSString *)key {
    return [[self.attributes objectForKey:attributeKey] objectForKey:key];
}

- (NSString *)effectNameForIndex:(NSNumber *)effectIndex {
    return [self.effects objectForKey:effectIndex];
}

- (NSNumber *)itemDefIndexForName:(NSString *)itemName {
    return [self.itemNameMap objectForKey:itemName];
}

- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key {
    return [[self.items objectForKey:defindex] objectForKey:key];
}

- (NSString *)itemLevelForScore:(NSNumber *)score
                   andLevelType:(NSString *)levelType {
    __block NSString *itemLevel;

    NSArray *itemLevels = [self.itemLevels objectForKey:levelType];
    [[itemLevels sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *level1, NSDictionary *level2) {
        return [level1[@"required_score"] compare:level2[@"required_score"]];
    }] enumerateObjectsUsingBlock:^(NSDictionary *level, NSUInteger idx, BOOL *stop) {
        if ([score intValue] < [level[@"required_score"] intValue]) {
            itemLevel = level[@"name"];
            *stop = YES;
        }
    }];

    return itemLevel;
}

- (NSDictionary *)itemSetForKey:(NSString *)itemSetKey {
    return [self.itemSets objectForKey:itemSetKey];
}

- (NSDictionary *)killEaterTypeForIndex:(NSNumber *)typeIndex {
    if (typeIndex == nil) {
        typeIndex = @0;
    }

    return [_killEaterTypes objectForKey:typeIndex];
}

- (NSString *)originNameForIndex:(NSUInteger)originIndex {
    return [self.origins objectAtIndex:originIndex];
}

- (NSString *)qualityNameForIndex:(NSNumber *)qualityIndex {
    return [self.qualities objectAtIndex:[qualityIndex integerValue]];
}

@end
