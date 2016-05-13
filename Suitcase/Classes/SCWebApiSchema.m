//
//  SCSchema.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import "SCAppDelegate.h"
#import "SCWebApiInventory.h"
#import "SCWebApiSchema.h"

@implementation SCWebApiSchema

static NSMutableDictionary *__schemas;

+ (void)initialize {
    __schemas = [NSMutableDictionary dictionary];
}

+ (void)clearSchemas {
    NSArray *appIds = [__schemas allKeys];
    if ([SCAbstractInventory.currentInventory isKindOfClass:[SCWebApiInventory class]]) {
        appIds = [appIds mutableCopy];
        [(NSMutableArray *)appIds removeObject:SCAbstractInventory.currentInventory.game.appId];
    }

    [__schemas removeObjectsForKeys:appIds];

    [SCAbstractInventory.inventories enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull steamId64, NSDictionary *_Nonnull inventories, BOOL * _Nonnull stop) {
        [inventories enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull appId, id<SCInventory> _Nonnull inventory, BOOL *_Nonnull stop) {
            if ([appIds containsObject:inventory.game.appId] && [inventory isKindOfClass:[SCWebApiInventory class]]) {
                ((SCWebApiInventory *)inventory).schema = nil;
            }
        }];
    }];
}

+ (void)restoreSchemas {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:documentsPath];

    NSString *fileName;
    while (fileName = [dirEnum nextObject]) {
        if ([[fileName pathExtension] isEqualToString:@"apischema"]) {
            SCWebApiSchema *schema = [NSKeyedUnarchiver unarchiveObjectWithFile:[documentsPath stringByAppendingPathComponent:fileName]];
            NSNumber *appId = [NSNumber numberWithInteger:[[[fileName lastPathComponent] stringByDeletingPathExtension] integerValue]];
            NSString *locale = [fileName stringByDeletingLastPathComponent];
            if (__schemas[appId] == nil) {
                __schemas[appId] = [NSMutableDictionary dictionary];
            }
            __schemas[appId][locale] = schema;
#ifdef DEBUG
            NSLog(@"Restored Web API item schema for app ID %@ and locale \"%@\".", appId, locale);
#endif
        }
    };
}

+ (NSDictionary *)schemas
{
    return [__schemas copy];
}

+ (AFHTTPRequestOperation *)schemaOperationForInventory:(SCWebApiInventory *)inventory
                                            andLanguage:(NSLocale *)locale
{
    NSString *language = locale.localeIdentifier;
    NSString *languageCode = [NSLocale componentsFromLocaleIdentifier:language][(NSString *)kCFLocaleLanguageCode];
    NSNumber *appId = inventory.game.appId;
    NSDate *lastUpdated = nil;

    if ([__schemas objectForKey:appId] == nil) {
        [__schemas setObject:[NSMutableDictionary dictionary] forKey:appId];
    } else {
        SCWebApiSchema *schema = [[__schemas objectForKey:appId] objectForKey:languageCode];
        if (schema != nil) {
            inventory.schema = schema;

            if ([schema.timestamp timeIntervalSinceNow] > -900) {
                return nil;
            }

            lastUpdated = schema.timestamp;
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
                                                                                            encoded:NO
                                                                                      modifiedSince:lastUpdated];
    ((NSMutableURLRequest *)schemaOperation.request).timeoutInterval = 60;
    [schemaOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
#ifdef DEBUG
        NSLog(@"Finished loading item schema for %@", appId);
#endif
        NSDictionary *schemaResponse = [responseObject objectForKey:@"result"];

        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            SCWebApiSchema *schema = [[SCWebApiSchema alloc] initWithDictionary:schemaResponse];
            [gameSchemas setObject:schema forKey:languageCode];
            inventory.schema = schema;

            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished" object:nil];
        } else {
            inventory.schema = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished"
                                                                object:[schemaResponse objectForKey:@"statusDetail"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 304) {
            inventory.schema.timestamp = [NSDate date];
        } else {
            inventory.schema = nil;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchemaFinished"
                                                            object:[error localizedDescription]];
    }];

    return schemaOperation;
}

+ (void)storeSchema:(SCWebApiSchema *)schema forAppId:(NSNumber *)appId andLanguage:(NSString *)locale {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *fileName = [NSString stringWithFormat:@"%@.apischema", appId];
    NSString *localePath = [documentsPath stringByAppendingPathComponent:locale];
    NSString *schemaPath = [localePath stringByAppendingPathComponent:fileName];

    [[NSFileManager defaultManager] createDirectoryAtPath:localePath withIntermediateDirectories:YES attributes:nil error:nil];

    [NSKeyedArchiver archiveRootObject:schema toFile:schemaPath];

#ifdef DEBUG
    NSLog(@"Stored Web API item schema for app ID %@ and locale \"%@\".", appId, locale);
#endif
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

    _timestamp = [NSDate date];

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
    itemLevels = [itemLevels sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *level1, NSDictionary *level2) {
        return [level1[@"required_score"] compare:level2[@"required_score"]];
    }];
    [itemLevels enumerateObjectsUsingBlock:^(NSDictionary *level, NSUInteger idx, BOOL *stop) {
        if ([score intValue] < [level[@"required_score"] intValue]) {
            itemLevel = level[@"name"];
            *stop = YES;
        }
    }];

    if (itemLevel == nil) {
        itemLevel = itemLevels.lastObject[@"name"];
    }

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

#pragma NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];

    _attributes = [aDecoder decodeObjectForKey:@"attributes"];
    _effects = [aDecoder decodeObjectForKey:@"effects"];
    _itemLevels = [aDecoder decodeObjectForKey:@"itemLevels"];
    _itemNameMap = [aDecoder decodeObjectForKey:@"itemNameMap"];
    _items = [aDecoder decodeObjectForKey:@"items"];
    _itemSets = [aDecoder decodeObjectForKey:@"itemSets"];
    _killEaterTypes = [aDecoder decodeObjectForKey:@"killEaterTypes"];
    _origins = [aDecoder decodeObjectForKey:@"origins"];
    _qualities = [aDecoder decodeObjectForKey:@"qualities"];
    _timestamp = [aDecoder decodeObjectForKey:@"timestamp"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.attributes forKey:@"attributes"];
    [aCoder encodeObject:self.effects forKey:@"effects"];
    [aCoder encodeObject:self.itemLevels forKey:@"itemLevels"];
    [aCoder encodeObject:self.itemNameMap forKey:@"itemNameMap"];
    [aCoder encodeObject:self.items forKey:@"items"];
    [aCoder encodeObject:self.itemSets forKey:@"itemSets"];
    [aCoder encodeObject:self.killEaterTypes forKey:@"killEaterTypes"];
    [aCoder encodeObject:self.origins forKey:@"origins"];
    [aCoder encodeObject:self.qualities forKey:@"qualities"];
    [aCoder encodeObject:self.timestamp forKey:@"timestamp"];
}

@end
