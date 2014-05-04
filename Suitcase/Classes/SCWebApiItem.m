//
//  SCWebApiItem.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import "SCWebApiItem.h"

@interface SCWebApiItem () {
    NSString *_killEaterDescription;
    NSNumber *_killEaterScore;
    NSNumber *_killEaterTypeIndex;
}
@end

NSString *const kSCHour = @"kSCHour";
NSString *const kSCHours = @"kSCHours";

@implementation SCWebApiItem

@synthesize attributes = _attributes;
@synthesize equippableClasses = _equippableClasses;
@synthesize equippedClasses = _equippedClasses;
@synthesize name = _name;
@synthesize position = _position;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCWebApiInventory *)anInventory {
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

        [mergedAttributes enumerateObjectsUsingBlock:^(NSDictionary *itemAttribute, NSUInteger idx, BOOL *stop) {
            if ([itemAttribute[@"defindex"] isEqualToNumber:@214]) {
                _killEaterScore = itemAttribute[@"value"];
            } else if ([itemAttribute[@"name"] isEqualToString:@"kill eater score type"]) {
                _killEaterTypeIndex = itemAttribute[@"float_value"];
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

        _attributes = [attributes sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *attribute1, NSDictionary *attribute2) {
            return [attribute1[@"defindex"] compare:attribute2[@"defindex"]];
        }];
    }

    return _attributes;
}

- (BOOL)belongsToItemSet {
    return self.itemSet != nil;
}

- (NSNumber *)defindex {
    return [self.dictionary objectForKey:@"defindex"];
}

- (NSString *)descriptionText {
    NSMutableString *description = [NSMutableString string];
    if ([self valueForKey:@"item_description"] != nil) {
        [description appendString:[[self valueForKey:@"item_description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:0];
    __block BOOL firstAttribute = YES;
    [self.attributes enumerateObjectsUsingBlock:^(NSDictionary *attribute, NSUInteger idx, BOOL *stop) {
        NSMutableString *attributeDescription = [[attribute objectForKey:@"description"] mutableCopy];
        if (attributeDescription != nil) {
            NSString *valueFormat = [attribute objectForKey:@"valueFormat"];
            NSString *value;
            if ([valueFormat isEqual:@"kill_eater"]) {
                value = [(NSNumber *)[attribute objectForKey:@"value"] stringValue];
            } else if ([valueFormat isEqual:@"value_is_account_id"]) {
                value = [[attribute objectForKey:@"accountInfo"] objectForKey:@"personaname"];
            } else if ([valueFormat isEqual:@"value_is_additive"]) {
                value = [(NSNumber *)attribute[@"floatValue"] stringValue];
                if (value == nil) {
                    value = [(NSNumber *)attribute[@"value"] stringValue];
                }
            } else if ([valueFormat isEqual:@"value_is_additive_percentage"]) {
                value = [[NSNumber numberWithDouble:[(NSNumber *)[attribute objectForKey:@"floatValue"] doubleValue] * 100] stringValue];
            } else if ([valueFormat isEqual:@"value_is_date"]) {
                double timestamp = [(NSNumber *)[attribute objectForKey:@"value"] doubleValue];
                if (timestamp == 0) {
                    attributeDescription = nil;
                } else {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)[attribute objectForKey:@"value"] doubleValue]];
                    value = [NSDateFormatter localizedStringFromDate:date
                                                           dateStyle:NSDateFormatterMediumStyle
                                                           timeStyle:NSDateFormatterShortStyle];
                }
            } else if ([valueFormat isEqual:@"value_is_inverted_percentage"]) {
                NSNumber *numberValue = attribute[@"floatValue"];
                if (numberValue == nil) {
                    numberValue = attribute[@"value"];
                }
                numberValue = [NSNumber numberWithDouble:(1 - [numberValue doubleValue]) * 100];
                value = [numberFormatter stringFromNumber:numberValue];
            } else if ([valueFormat isEqualToString:@"value_is_mins_as_hours"]) {
                int hours = [(NSNumber *)attribute[@"floatValue"] floatValue] / 60;
                NSString *formatString = (hours == 1) ? NSLocalizedString(kSCHour, kSCHour) : NSLocalizedString(kSCHours, kSCHours);
                value = [NSString stringWithFormat:formatString, hours];
            } else if ([valueFormat isEqual:@"value_is_particle_index"]) {
                value = [self.inventory.schema effectNameForIndex:[attribute objectForKey:@"value"]];
                if (value == nil) {
                    value = [self.inventory.schema effectNameForIndex:[attribute objectForKey:@"floatValue"]];
                }
            } else if ([valueFormat isEqual:@"value_is_percentage"]) {
                NSNumber *numberValue = attribute[@"floatValue"];
                if (numberValue == nil) {
                    numberValue = attribute[@"value"];
                }
                numberValue = [NSNumber numberWithDouble:([numberValue doubleValue] - 1) * 100];
                value = [numberFormatter stringFromNumber:numberValue];
            }

            if (value != nil) {
                [attributeDescription replaceOccurrencesOfString:@"%s1"
                                                      withString:value
                                                         options:NSLiteralSearch
                                                           range:NSMakeRange(0, [attributeDescription length])];
            }

            if ([description length] > 0) {
                if (firstAttribute) {
                    [description appendString:@"\n"];
                }
                [description appendString:@"\n"];
            }

            [description appendString:attributeDescription];
            firstAttribute = NO;
        };
    }];

    [description replaceOccurrencesOfString:@"<br>"
                                 withString:@"\n"
                                    options:NSCaseInsensitiveSearch
                                      range:NSMakeRange(0, [description length])];
    [description replaceOccurrencesOfString:@"</?font( .*)?>"
                                 withString:@""
                                    options:NSRegularExpressionSearch
                                      range:NSMakeRange(0, [description length])];

    return [NSString stringWithString:description];
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

- (BOOL)hasOrigin {
    return YES;
}

- (BOOL)hasQuality {
    return YES;
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:[self valueForKey:@"image_url"]];
}

- (NSURL *)imageUrl {
    NSString *url = [self valueForKey:@"image_url_large"];
    if ([url isEqualToString:@""]) {
        return self.iconUrl;
    }

    return [NSURL URLWithString:url];
}

- (BOOL)isKillEater {
    return _killEaterScore != nil;
}

- (NSDictionary *)itemSet {
    NSString *itemSetKey = [self valueForKey:@"item_set"];
    return [self.inventory.schema itemSetForKey:itemSetKey];
}

- (NSString *)itemType {
    return [self valueForKey:@"item_type_name"];
}

- (NSString *)killEaterDescription {
    if (_killEaterDescription == nil) {
        NSDictionary *killEaterType = [self.inventory.schema killEaterTypeForIndex:_killEaterTypeIndex];
        NSString *itemLevel = [self.inventory.schema itemLevelForScore:_killEaterScore
                                                          andLevelType:killEaterType[@"level_data"]
                                                           andItemType:self.itemType];

        _killEaterDescription = [NSString stringWithFormat:@"%@ %@\n%@", _killEaterScore, killEaterType[@"type_name"], itemLevel];
    }

    return _killEaterDescription;
}

- (NSNumber *)level {
    return [self.dictionary objectForKey:@"level"];
}

- (NSString *)levelText {
    return [NSString stringWithFormat:@"Level %@ %@", self.level, self.itemType];
}

- (NSString *)name {
    if (_name == nil) {
        NSMutableString *name = [[self valueForKey:@"item_name"] mutableCopy];
        if ([name rangeOfString:@"%s1"].location != NSNotFound) {
            [name replaceOccurrencesOfString:@"%s1"
                                  withString:self.level.stringValue
                                     options:NSLiteralSearch
                                       range:NSMakeRange(0, [name length])];
        }

        _name = [name copy];
    }

    return _name;
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

- (NSNumber *)quality {
    return [self.dictionary objectForKey:@"quality"];
}

- (UIColor *)qualityColor {
    NSInteger itemQuality = [self.quality integerValue];
    if (itemQuality == 1) {
        return [UIColor colorWithRed:0.0 green:0.39 blue:0.0 alpha:1.0];
    } else if (itemQuality == 3) {
        return [UIColor colorWithRed:0.11 green:0.39 blue:0.82 alpha:1.0];
    } else if (itemQuality == 5) {
        return [UIColor colorWithRed:0.53 green:0.33 blue:0.82 alpha:1.0];
    } else if (itemQuality == 7) {
        return [UIColor colorWithRed:0.11 green:0.52 blue:0.17 alpha:1.0];
    } else if (itemQuality == 11) {
        return [UIColor colorWithRed:0.76 green:0.52 blue:0.17 alpha:1.0];
    }

    return [UIColor colorWithWhite:0.2 alpha:1.0];
}

- (NSString *)qualityName {
    return [self.inventory.schema qualityNameForIndex:self.quality];
}

- (NSNumber *)quantity {
    return [self.dictionary objectForKey:@"quantity"];
}

- (id)valueForKey:(NSString *)key {
    return [self.inventory.schema itemValueForDefIndex:self.defindex andKey:key];
}

@end
