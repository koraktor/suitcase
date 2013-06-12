//
//  SCSchema.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "SCAppDelegate.h"
#import "SCInventory.h"
#import "SCSchema.h"

@implementation SCSchema

static NSMutableDictionary *__schemas;

+ (SCSchema *)brokenSchema
{
    SCSchema *schema = [[SCSchema alloc] init];

    return schema;
}

+ (NSDictionary *)schemas
{
    return [__schemas copy];
}

+ (AFJSONRequestOperation *)schemaOperationForInventory:(SCInventory *)inventory
                                            andLanguage:(NSString *)language
                                           andCondition:(NSCondition *)condition
{
    if (__schemas == nil) {
        __schemas = [NSMutableDictionary dictionary];
    }

    NSNumber *appId = inventory.game.appId;

    if ([__schemas objectForKey:appId] == nil) {
        [__schemas setObject:[NSMutableDictionary dictionary] forKey:appId];
    } else {
        SCSchema *schema = [[__schemas objectForKey:appId] objectForKey:language];
        if (schema != nil) {
            [condition lock];
            inventory.schema = schema;
            [condition signal];
            [condition unlock];
            return nil;
        }
    }
    __block NSMutableDictionary *gameSchemas = [__schemas objectForKey:appId];

    NSDictionary *params = [NSDictionary dictionaryWithObject:language forKey:@"language"];
    AFJSONRequestOperation *schemaOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:[NSString stringWithFormat:@"IEconItems_%@", appId]
                                                                                          andMethod:@"GetSchema"
                                                                                         andVersion:1
                                                                                     withParameters:params];
    [schemaOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [condition lock];
        NSDictionary *schemaResponse = [responseObject objectForKey:@"result"];

        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            SCSchema *schema = [[SCSchema alloc] initWithDictionary:schemaResponse];
            [gameSchemas setObject:schema forKey:language];
            inventory.schema = schema;
            [condition signal];
            [condition unlock];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"Error loading the inventory: %@", [schemaResponse objectForKey:@"statusDetail"]];
            inventory.schema = [SCSchema brokenSchema];
            [condition signal];
            [condition unlock];
            [SCAppDelegate errorWithMessage:errorMessage];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading item schema: %@", [error localizedDescription]];
        [condition lock];
        inventory.schema = [SCSchema brokenSchema];
        [condition signal];
        [condition unlock];
        [SCAppDelegate errorWithMessage:errorMessage];
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

- (NSString *)itemLevelForScore:(NSUInteger)score andLevelType:(NSString *)levelType {
    __block NSString *itemLevel;

    NSArray *itemLevels = [self.itemLevels objectForKey:levelType];
    [[itemLevels sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *level1, NSDictionary *level2) {
        return [[level1 objectForKey:@"required_score"] compare:[level2 objectForKey:@"required_score"]];
    }] enumerateObjectsUsingBlock:^(NSDictionary *level, NSUInteger idx, BOOL *stop) {
        if (score < [[level objectForKey:@"required_score"] integerValue]) {
            itemLevel = [level objectForKey:@"name"];
            *stop = YES;
        }
    }];

    return itemLevel;
}

- (NSDictionary *)itemSetForKey:(NSString *)itemSetKey {
    return [self.itemSets objectForKey:itemSetKey];
}

- (NSDictionary *)killEaterTypeForIndex:(NSNumber *)typeIndex {
    return [_killEaterTypes objectForKey:typeIndex];
}

- (NSString *)originNameForIndex:(NSUInteger)originIndex {
    return [self.origins objectAtIndex:originIndex];
}

- (NSString *)qualityNameForIndex:(NSUInteger)qualityIndex {
    return [self.qualities objectAtIndex:qualityIndex];
}

@end
