//
//  SCItem.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "SCItem.h"

@implementation SCItem

@synthesize attributes = _attributes;
@synthesize equippableClasses = _equippableClasses;
@synthesize equippedClasses = _equippedClasses;
@synthesize position = _position;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCInventory *)anInventory {
    self.dictionary = aDictionary;
    self.inventory  = anInventory;

    _equippableClasses = -1;
    _equippedClasses   = -1;

    return self;
}

- (NSArray *)attributes {
    if (_attributes == nil) {
        NSArray *schemaAttributes = [self valueForKey:@"attributes"];
        NSArray *itemAttributes = self.dictionary[@"attributes"];

        NSMutableDictionary *generalAttributes = [NSMutableDictionary dictionary];
        [schemaAttributes enumerateObjectsUsingBlock:^(NSDictionary *attributeData, NSUInteger idx, BOOL *stop) {
            NSObject *attributeKey = attributeData[@"defindex"];
            if (attributeKey == nil) {
                attributeKey = attributeData[@"name"];
            }

            if (attributeKey != nil) {
                NSDictionary *schemaAttributeData = self.inventory.schema.attributes[attributeKey];
                NSNumber *defindex = schemaAttributeData[@"defindex"];
                NSMutableDictionary *attributes = [attributeData mutableCopy];
                [attributes addEntriesFromDictionary:schemaAttributeData];
                generalAttributes[defindex] = [attributes copy];
            }
        }];

        NSMutableDictionary *specificAttributes = [NSMutableDictionary dictionary];
        [itemAttributes enumerateObjectsUsingBlock:^(NSDictionary *attributeData, NSUInteger idx, BOOL *stop) {
            NSObject *attributeKey = attributeData[@"defindex"];
            if (attributeKey == nil) {
                attributeKey = attributeData[@"name"];
            }

            if (attributeKey != nil) {
                NSDictionary *schemaAttributeData = self.inventory.schema.attributes[attributeKey];
                NSNumber *defindex = schemaAttributeData[@"defindex"];
                NSMutableDictionary *attributes = [attributeData mutableCopy];
                [attributes addEntriesFromDictionary:schemaAttributeData];
                specificAttributes[defindex] = [attributes copy];
            }
        }];

        NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionaryWithDictionary:generalAttributes];
        [specificAttributes enumerateKeysAndObjectsUsingBlock:^(id defindex, NSDictionary *attribute, BOOL *stop) {
            NSDictionary *currentAttribute = [attributesDictionary objectForKey:defindex];
            if (currentAttribute == nil) {
                [attributesDictionary setObject:attribute forKey:defindex];
            } else {
                NSMutableDictionary *newAttribute = [NSMutableDictionary dictionaryWithDictionary:currentAttribute];
                [newAttribute addEntriesFromDictionary:attribute];
                [attributesDictionary setObject:newAttribute forKey:defindex];
            }
        }];

        NSArray *mergedAttributes = [attributesDictionary allValues];
        NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:[mergedAttributes count]];

        __block NSInteger killEaterScore = -1;
        __block NSUInteger killEaterTypeIndex = 0;

        [mergedAttributes enumerateObjectsUsingBlock:^(NSDictionary *itemAttribute, NSUInteger idx, BOOL *stop) {
            if ([itemAttribute[@"defindex"] isEqual:[NSNumber numberWithInt:214]]) {
                killEaterScore = [itemAttribute[@"value"] integerValue];
            } else if ([itemAttribute[@"name"] isEqual:@"kill eater score type"]) {
                killEaterTypeIndex = [itemAttribute[@"value"] integerValue];
            } else {
                if (itemAttribute[@"defindex"] != nil) {
                    NSMutableDictionary *attribute = [NSMutableDictionary dictionary];
                    [attribute setValue:itemAttribute[@"defindex"] forKey:@"defindex"];
                    [attribute setValue:itemAttribute[@"account_info"] forKey:@"accountInfo"];
                    [attribute setValue:itemAttribute[@"description_string"] forKey:@"description"];
                    [attribute setValue:itemAttribute[@"float_value"] forKey:@"floatValue"];
                    [attribute setValue:itemAttribute[@"value"] forKey:@"value"];
                    [attribute setValue:itemAttribute[@"description_format"] forKey:@"valueFormat"];

                    [attributes addObject:[attribute copy]];
                }
            }
        }];

        if (killEaterScore != -1) {
            NSDictionary *killEaterType = [self.inventory.schema killEaterTypeForIndex:[NSNumber numberWithUnsignedInteger:killEaterTypeIndex]];
            NSString *itemLevel = [self.inventory.schema itemLevelForScore:killEaterScore
                                                              andLevelType:killEaterType[@"level_data"]
                                                               andItemType:self.itemType];

            NSMutableDictionary *attribute = [NSMutableDictionary dictionary];
            attribute[@"defindex"]    = @0;
            attribute[@"description"] = [NSString stringWithFormat:@"%@\n%%s1 %@", itemLevel, killEaterType[@"type_name"]];
            attribute[@"value"]       = [NSNumber numberWithInteger:killEaterScore];
            attribute[@"valueFormat"] = @"kill_eater";

            [attributes addObject:attribute];
        }

        _attributes = [attributes copy];
    }

    return _attributes;
}

- (NSNumber *)defindex {
    return [self.dictionary objectForKey:@"defindex"];
}

- (NSString *)description {
    return [[self valueForKey:@"item_description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (int)equippableClasses {
    if (_equippableClasses == -1 ) {
        _equippableClasses = 0;
        NSArray *classes = (NSArray *)[self valueForKey:@"used_by_classes"];

        if ([classes count] == 0) {
            _equippableClasses = 511;
        } else {
            if ([classes containsObject:@"Scout"]) {
                _equippableClasses = _equippableClasses | 1;
            }
            if ([classes containsObject:@"Soldier"]) {
                _equippableClasses = _equippableClasses | 4;
            }
            if ([classes containsObject:@"Pyro"]) {
                _equippableClasses = _equippableClasses | 64;
            }
            if ([classes containsObject:@"Demoman"]) {
                _equippableClasses = _equippableClasses | 8;
            }
            if ([classes containsObject:@"Heavy"]) {
                _equippableClasses = _equippableClasses | 32;
            }
            if ([classes containsObject:@"Engineer"]) {
                _equippableClasses = _equippableClasses | 256;
            }
            if ([classes containsObject:@"Medic"]) {
                _equippableClasses = _equippableClasses | 16;
            }
            if ([classes containsObject:@"Sniper"]) {
                _equippableClasses = _equippableClasses | 2;
            }
            if ([classes containsObject:@"Spy"]) {
                _equippableClasses = _equippableClasses | 128;
            }
        }
    }

    return _equippableClasses;
}

- (int)equippedClasses {
    if(_equippedClasses == -1) {
        _equippedClasses = 0;
        [(NSArray *)[self.dictionary objectForKey:@"equipped"] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            int classId = [[obj objectForKey:@"class"] intValue];
            if (classId == 0) {
                classId = 1;
            }
            _equippedClasses = _equippedClasses | (1 << (classId - 1));
        }];
    }

    return _equippedClasses;
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:[self valueForKey:@"image_url"]];
}

- (NSURL *)imageUrl {
    return [NSURL URLWithString:[self valueForKey:@"image_url_large"]];
}

- (NSDictionary *)itemSet {
    NSString *itemSetKey = [self valueForKey:@"item_set"];
    return [self.inventory.schema itemSetForKey:itemSetKey];
}

- (NSString *)itemType {
    return [self valueForKey:@"item_type_name"];
}

- (NSNumber *)level {
    return [self.dictionary objectForKey:@"level"];
}

- (NSString *)name {
    return [self valueForKey:@"item_name"];
}

- (NSString *)origin {
    NSNumber *originIndex = [self.dictionary objectForKey:@"origin"];
    return [self.inventory.schema originNameForIndex:[originIndex unsignedIntValue]];
}

- (NSNumber *)position {
    if (_position == nil) {
        int inventoryMask = [(NSNumber *)[self.dictionary objectForKey:@"inventory"] intValue];
        _position = [NSNumber numberWithInt:(inventoryMask & 0xFFFF)];
    }

    return _position;
}

- (NSString *)quality {
    NSNumber *qualityIndex = [self.dictionary objectForKey:@"quality"];
    return [self.inventory.schema qualityNameForIndex:[qualityIndex unsignedIntValue]];
}

- (NSNumber *)quantity {
    return [self.dictionary objectForKey:@"quantity"];
}

- (id)valueForKey:(NSString *)key {
    return [self.inventory.schema itemValueForDefIndex:self.defindex andKey:key];
}

@end
