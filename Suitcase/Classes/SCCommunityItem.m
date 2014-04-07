//
//  SCCommunityItem.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "HexColor.h"

#import "SCCommunityItem.h"

@interface SCCommunityItem () {
    NSString *_description;
    NSDictionary *_tags;
}
@end

@implementation SCCommunityItem

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCCommunityInventory *)anInventory
         andItemCategory:(NSNumber *)itemCategory
{
    self.dictionary = aDictionary;
    self.inventory  = anInventory;

    _equippableClasses = -1;
    _equippedClasses   = -1;
    _itemCategory = itemCategory;

    return self;
}

- (NSString *)description {
    if (_description == nil) {
        _description = [NSMutableString string];

        for (NSDictionary *description in [self valueForKey:@"descriptions"]) {
            NSString *descriptionText = [description[@"value"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            if ([descriptionText length] == 0) {
                continue;
            }

            if ([_description length] > 0) {
                [((NSMutableString *)_description) appendString:@"\n\n"];
            }

            if ([self.tags[@"item_class"][@"raw_value"] isEqualToString:@"item_class_4"]) {
#warning TODO
            }

            [((NSMutableString *)_description) appendString:descriptionText];
        }

        _description = [_description copy];
    }

    return _description;
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://cdn.steamcommunity.com/economy/image/%@/96fx96f", [self valueForKey:@"icon_url"]]];
}

- (NSURL *)imageUrl {
    NSString *url = [self valueForKey:@"icon_url_large"];
    if (url == nil || [url isEqualToString:@""]) {
        url = [self valueForKey:@"icon_url"];
    }

    return [NSURL URLWithString:[NSString stringWithFormat:@"http://cdn.steamcommunity.com/economy/image/%@/330x192", url]];
}

- (NSDictionary *)itemSet {
    return nil;
}

- (NSString *)itemType {
    return [self valueForKey:@"type"];
}

- (NSString *)levelText {
    return [self valueForKey:@"type"];
}

- (NSString *)name {
    return [self valueForKey:@"name"];
}

- (NSString *)origin {
    return @"unknown";
}

- (NSNumber *)position {
    NSInteger category = [self.itemCategory integerValue];
    NSInteger position = [[self valueForKey:@"pos"] integerValue];
    return [NSNumber numberWithInteger:category * 100000 + position];
}

- (NSNumber *)quality {
    return @0;
}

- (UIColor *)qualityColor {
    return self.tags[@"Rarity"][@"color"];
}

- (NSString *)qualityName {
    return nil;
}

- (NSNumber *)quantity {
    return [self valueForKey:@"amount"];
}

- (NSDictionary *)tags {
    if (_tags == nil) {
        _tags = [NSMutableDictionary dictionary];

        for (NSDictionary *rawTag in [self valueForKey:@"tags"]) {
            NSDictionary *tag = @{
                                  @"name": rawTag[@"category_name"],
                                  @"raw_value": rawTag[@"internal_name"],
                                  @"value": rawTag[@"name"]
                                };
            if (rawTag[@"color"]) {
                tag = [tag mutableCopy];
                ((NSMutableDictionary *)tag)[@"color"] = [UIColor colorWithHexString:rawTag[@"color"]];
                tag = [tag copy];
            }
            ((NSMutableDictionary *)_tags)[rawTag[@"category"]] = tag;
        }

        _tags = [_tags copy];
    }

    return _tags;
}

- (id)valueForKey:(NSString *)key {
    return [self.dictionary objectForKey:key];
}

@end
