//
//  SCSchema.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCSchema.h"

@implementation SCSchema

@synthesize attributes = _attributes;
@synthesize effects = _effects;
@synthesize items = _items;
@synthesize origins = _origins;
@synthesize qualities = _qualities;

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
    [itemsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.items setValue:obj forKey:[obj objectForKey:@"defindex"]];
    }];
    _items = [_items copy];

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
    for (int i = 0; i < [effectsArray count]; i ++) {
        [(NSMutableArray *)_qualities addObject:[NSNull null]];
    }
    [qualityKeys enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *index, BOOL *stop) {
        [(NSMutableArray *)self.qualities replaceObjectAtIndex:[index integerValue]
                                                    withObject:[qualityNames objectForKey:key]];
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

- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key {
    return [[self.items objectForKey:defindex] objectForKey:key];
}

- (NSString *)originNameForIndex:(NSUInteger)originIndex {
    return [self.origins objectAtIndex:originIndex];
}

- (NSString *)qualityNameForIndex:(NSUInteger)qualityIndex {
    return [self.qualities objectAtIndex:qualityIndex];
}

@end
