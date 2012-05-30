//
//  SCSchema.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCSchema.h"

@implementation SCSchema

@synthesize attributes = _attributes;
@synthesize items = _items;
@synthesize origins = _origins;
@synthesize qualities = _qualities;

- (id)initWithDictionary:(NSDictionary *)dictionary {
    NSArray *attributesArray = [dictionary objectForKey:@"attributes"];
    self.attributes = [NSMutableDictionary dictionaryWithCapacity:[attributesArray count]];
    [attributesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.attributes setValue:obj forKey:[obj objectForKey:@"defindex"]];
    }];
    
    NSArray *itemsArray = [dictionary objectForKey:@"items"];
    self.items = [NSMutableDictionary dictionaryWithCapacity:[itemsArray count]];
    [itemsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.items setValue:obj forKey:[obj objectForKey:@"defindex"]];
    }];
    
    NSArray *originsArray = [dictionary objectForKey:@"originNames"];
    self.origins = [NSMutableArray arrayWithCapacity:[originsArray count]];
    [originsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *index = [obj objectForKey:@"origin"];
        [(NSMutableArray *)self.origins insertObject:[obj objectForKey:@"name"] atIndex:[index unsignedIntValue]];
    }];
    
    NSDictionary *qualityKeys = [dictionary objectForKey:@"qualities"];
    NSDictionary *qualityNames = [dictionary objectForKey:@"qualityNames"];
    _qualities = [NSMutableArray arrayWithArray:[qualityNames allValues]];
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
