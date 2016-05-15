//
//  SCWebApiItem.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import "SCItemSet.h"
#import "SCLanguage.h"

#import "SCWebApiItem.h"

@interface SCWebApiItem () {
    NSString *_killEaterDescription;
    NSNumber *_killEaterScore;
    NSNumber *_killEaterTypeIndex;
    SCItemSet *_itemSet;
}
@end

NSString *const kSCHour = @"kSCHour";
NSString *const kSCHours = @"kSCHours";
const NSUInteger kSCKillEaterDefindex = 214;

@implementation SCWebApiItem

@synthesize position = _position;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCWebApiInventory *)anInventory {
    self.dictionary = aDictionary;
    self.inventory  = anInventory;

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
                if (defindex != nil) {
                    NSMutableDictionary *attributes = [attributeData mutableCopy];
                    [attributes addEntriesFromDictionary:schemaAttributeData];
                    specificAttributes[defindex] = [attributes copy];
                }
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
            if ([itemAttribute[@"defindex"] isEqualToNumber:[NSNumber numberWithInt:kSCKillEaterDefindex]]) {
                _killEaterScore = itemAttribute[@"value"];
            } else if ([itemAttribute[@"name"] isEqualToString:@"kill eater score type"]) {
                _killEaterTypeIndex = itemAttribute[@"float_value"];
            } else {
                if (itemAttribute[@"defindex"] != nil) {
                    NSMutableDictionary *attribute = [NSMutableDictionary dictionary];
                    [attribute setValue:itemAttribute[@"defindex"] forKey:@"defindex"];
                    [attribute setValue:itemAttribute[@"account_info"] forKey:@"accountInfo"];
                    [attribute setValue:itemAttribute[@"description_string"] forKey:@"description"];
                    [attribute setValue:itemAttribute[@"description_format"] forKey:@"valueFormat"];

                    if ([itemAttribute[@"stored_as_integer"] isEqualToNumber:@1]) {
                        [attribute setValue:itemAttribute[@"value"] forKey:@"value"];
                    } else {
                        [attribute setValue:itemAttribute[@"float_value"] forKey:@"value"];
                    }

                    [attributes addObject:attribute];
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

- (void)clearCachedValues {
    _attributes = nil;
    _itemSet = nil;
    _killEaterDescription = nil;
    _name = nil;
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
                value = [(NSNumber *)attribute[@"value"] stringValue];
            } else if ([valueFormat isEqual:@"value_is_additive_percentage"]) {
                value = [[NSNumber numberWithDouble:[(NSNumber *)[attribute objectForKey:@"value"] doubleValue] * 100] stringValue];
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
                NSNumber *numberValue = [NSNumber numberWithDouble:(1 - [attribute[@"value"] doubleValue]) * 100];
                value = [numberFormatter stringFromNumber:numberValue];
            } else if ([valueFormat isEqualToString:@"value_is_mins_as_hours"]) {
                int hours = [(NSNumber *)attribute[@"value"] floatValue] / 60;
                NSString *formatString = (hours == 1) ? NSLocalizedString(kSCHour, kSCHour) : NSLocalizedString(kSCHours, kSCHours);
                value = [NSString stringWithFormat:formatString, hours];
            } else if ([valueFormat isEqual:@"value_is_particle_index"]) {
                value = [self.inventory.schema effectNameForIndex:[attribute objectForKey:@"value"]];
            } else if ([valueFormat isEqual:@"value_is_percentage"]) {
                NSNumber *numberValue = [NSNumber numberWithDouble:([attribute[@"value"] doubleValue] - 1) * 100];
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

- (BOOL)hasOrigin {
    return YES;
}

- (BOOL)hasQuality {
    return YES;
}

- (NSString *)iconIdentifier {
    return [[[self valueForKey:@"image_url"] lastPathComponent] stringByDeletingPathExtension];
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:[self valueForKey:@"image_url"]];
}

- (NSString *)imageIdentifier {
    return [[[self valueForKey:@"image_url_large"] lastPathComponent] stringByDeletingPathExtension];
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

- (BOOL)isMarketable {
    return NO;
}

- (BOOL)isTradable {
    NSNumber *cannotTradeFlag = self.dictionary[@"flag_cannot_trade"];
    if (cannotTradeFlag == nil) {
        return YES;
    }

    return ![cannotTradeFlag boolValue];
}

- (SCItemSet *)itemSet {
    if (_itemSet == nil) {
        NSString *itemSetKey = [self valueForKey:@"item_set"];
        if (itemSetKey == nil) {
            return nil;
        }

        NSDictionary *itemSetData = self.inventory.schema.itemSets[itemSetKey];
        NSMutableArray *itemSetItems = [NSMutableArray arrayWithCapacity:[itemSetData[@"items"] count]];
        [itemSetData[@"items"] enumerateObjectsUsingBlock:^(NSString *itemName, NSUInteger idx, BOOL *stop) {
            NSNumber *defindex = [self.inventory.schema itemDefIndexForName:itemName];
            NSURL *imageUrl = [NSURL URLWithString:[self.inventory.schema itemValueForDefIndex:defindex
                                                                                        andKey:@"image_url"]];
            itemName = [self.inventory.schema itemValueForDefIndex:defindex andKey:@"item_name"];

            [itemSetItems addObject:@{ @"name": itemName, @"imageUrl": imageUrl }];
        }];

        _itemSet = [SCItemSet itemSetWithId:itemSetData[@"item_set"]
                                    andName:itemSetData[@"name"]
                                   andItems:itemSetItems];
    }

    return _itemSet;
}

- (NSString *)itemType {
    return [self valueForKey:@"item_type_name"];
}

- (NSNumber *)level {
    return [self.dictionary objectForKey:@"level"];
}

- (NSString *)levelFormat {
    if ([[[SCLanguage currentLanguage] localeIdentifier] isEqualToString:@"de"]) {
        return @"%2$@ (%1$@)";
    } else {
        return @"%@ %@";
    }
}

- (NSString *)levelText {
    if (_killEaterDescription != nil) {
        return _killEaterDescription;
    }

    if ([self isKillEater]) {
        NSDictionary *killEaterType = [self.inventory.schema killEaterTypeForIndex:_killEaterTypeIndex];
        NSString *itemLevel = [self.inventory.schema itemLevelForScore:_killEaterScore
                                                          andLevelType:killEaterType[@"level_data"]];
        NSString *killEaterLevel;
        if (itemLevel == nil) {
            killEaterLevel = self.itemType;
        } else {
            killEaterLevel = [NSString stringWithFormat:[self levelFormat], itemLevel, self.itemType];
        }

        _killEaterDescription = [NSString stringWithFormat:@"%@ %@ – %@", _killEaterScore, killEaterType[@"type_name"], killEaterLevel];

        return _killEaterDescription;
    }

    return [NSString stringWithFormat:@"Level %@ %@", self.level, self.itemType];
}

- (NSString *)name {
    if (_name == nil) {
        if (self.dictionary[@"custom_name"] != nil) {
            _name = self.dictionary[@"custom_name"];
        } else {
            [self attributes];

            NSMutableString *name = [[self valueForKey:@"item_name"] mutableCopy];
            if ([name rangeOfString:@"%s1"].location != NSNotFound) {
                [name replaceOccurrencesOfString:@"%s1"
                                      withString:self.level.stringValue
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, [name length])];
            }

            if ([self isKillEater]) {
                NSDictionary *killEaterType = [self.inventory.schema killEaterTypeForIndex:_killEaterTypeIndex];
                NSString *itemLevel = [self.inventory.schema itemLevelForScore:_killEaterScore
                                                                  andLevelType:killEaterType[@"level_data"]];
                _name = [NSString stringWithFormat:[self levelFormat], itemLevel, name];
            } else {
                _name = [NSString stringWithString:name];
            }
        }
    }

    return _name;
}

- (NSString *)origin {
    return [self.inventory originNameForIndex:[self.originIndex unsignedIntValue]];
}

- (NSNumber *)originIndex {
    return [self.dictionary objectForKey:@"origin"];
}

- (NSNumber *)position {
    if (_position == nil) {
        int inventoryMask = [(NSNumber *)[self.dictionary objectForKey:@"inventory"] intValue];
        int unpositioned = inventoryMask & 0x7F000000;
        if (unpositioned > 0) {
            _position = [NSNumber numberWithInt:unpositioned >> 24];
        } else {
            _position = [NSNumber numberWithInt:(inventoryMask & 0xFFFF) << 8];
        }
    }

    return _position;
}

- (NSNumber *)quality {
    return [self.dictionary objectForKey:@"quality"];
}

- (UIColor *)qualityColor {
    return [UIColor colorWithWhite:0.2 alpha:1.0];
}

- (NSString *)qualityName {
    return [self.inventory.schema qualityNameForIndex:self.quality];
}

- (NSNumber *)quantity {
    return [self.dictionary objectForKey:@"quantity"];
}

- (NSString *)style {
    NSNumber *styleIndex = self.dictionary[@"style"];
    if (styleIndex == nil) {
        return nil;
    }

    return [self valueForKey:@"styles"][styleIndex.unsignedIntegerValue][@"name"];
}

- (id)valueForKey:(NSString *)key {
    return [self.inventory.schema itemValueForDefIndex:self.defindex andKey:key];
}

#pragma NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];

    _attributes = [aDecoder decodeObjectForKey:@"attributes"];
    _dictionary = [aDecoder decodeObjectForKey:@"dictionary"];
    _position = [aDecoder decodeObjectForKey:@"position"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_attributes forKey:@"attributes"];
    [aCoder encodeObject:_dictionary forKey:@"dictionary"];
    [aCoder encodeObject:_position forKey:@"position"];
}

@end
