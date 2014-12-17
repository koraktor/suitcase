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

static NSDateFormatter *kDateFormatter;
static NSRegularExpression *kDateRegex;
static NSRegularExpression *kHtmlRegex;
static NSString *kIconSize;
static NSString *kImageSize;

+ (void)initialize {
    kDateFormatter = [[NSDateFormatter alloc] init];
    kDateFormatter.dateStyle = NSDateFormatterLongStyle;
    kDateFormatter.locale = [NSLocale currentLocale];
    kDateFormatter.timeStyle = NSDateFormatterNoStyle;

    NSError *regexError;
    kDateRegex = [[NSRegularExpression alloc] initWithPattern:@"\\[date\\](\\d+)\\[/date\\]"
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&regexError];

    NSUInteger cellHeight = 44;
    NSUInteger iconHeight = [[UIScreen mainScreen] scale] * cellHeight;
    kIconSize = [NSString stringWithFormat:@"%1$lux%1$lu", (unsigned long)iconHeight];

    NSUInteger imageHeight;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        imageHeight = 256;
    } else {
        imageHeight = 128;
    }
    imageHeight = [[UIScreen mainScreen] scale] * imageHeight;
    kImageSize = [NSString stringWithFormat:@"%1$lux%1$lu", (unsigned long)imageHeight];
}

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

- (BOOL)belongsToItemSet {
    return NO;
}

- (NSString *)descriptionText {
    if (_description == nil) {
        NSMutableString *description = [[NSMutableString alloc] init];

        id descriptions = [self valueForKey:@"descriptions"];
        if ([descriptions isKindOfClass:[NSArray class]]) {
            for (NSDictionary *descriptionData in descriptions) {
                __block NSString *descriptionText = [descriptionData[@"value"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                if ([descriptionText length] == 0) {
                    continue;
                }

                if ([self.inventory.game isSteam] &&
                    [self.tags[@"item_class"][@"raw_value"] isEqualToString:@"item_class_4"] &&
                    [descriptionData[@"type"] isEqualToString:@"html"]) {
                    continue;
                }

                [kDateRegex enumerateMatchesInString:descriptionText
                                            options:0
                                              range:NSMakeRange(0, [descriptionText length])
                                         usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
                                             NSTimeInterval timestamp = [[descriptionText substringWithRange:[result rangeAtIndex:1]] integerValue];
                                             NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
                                             NSString *dateString = [kDateFormatter stringFromDate:date];
                                             descriptionText = [descriptionText stringByReplacingCharactersInRange:result.range
                                                                                                        withString:dateString];
                }];

                if ([description length] > 0) {
                    [description appendString:@"\n\n"];
                }

                [description appendString:descriptionText];
            }
        }

        NSString *strippedDescription = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (strippedDescription.length == 0) {
            _description = strippedDescription;
        } else {
            _description = [NSString stringWithString:description];
        }
    }

    return _description;
}

- (BOOL)hasOrigin {
    return NO;
}

- (BOOL)hasQuality {
    return self.qualityName != nil;
}

- (NSString *)iconIdentifier {
    return [[self valueForKey:@"icon_url"] stringByAppendingPathComponent:kIconSize];
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://cdn.steamcommunity.com/economy/image/%@", self.iconIdentifier]];
}

- (NSString *)imageIdentifier {
    NSString *identifier = [self valueForKey:@"icon_url_large"];
    if (identifier == nil || [identifier isEqualToString:@""]) {
        identifier = [self valueForKey:@"icon_url"];
    }

    return [identifier stringByAppendingPathComponent:kImageSize];
}

- (NSURL *)imageUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://cdn.steamcommunity.com/economy/image/%@", self.imageIdentifier]];
}

- (BOOL)isKillEater {
    return NO;
}

- (BOOL)isMarketable {
    return [[self valueForKey:@"marketable"] boolValue];
}

- (BOOL)isTradable {
    return [[self valueForKey:@"tradable"] boolValue];
}

- (SCItemSet *)itemSet {
    return nil;
}

- (NSString *)itemType {
    NSString *itemType;

    if ([self.inventory.game isSteam] && [[self.tags allKeys] containsObject:@"item_class"]) {
        itemType = self.tags[@"item_class"][@"value"];
    }
    if (itemType == nil) {
        itemType = [self valueForKey:@"type"];
    }

    return itemType;
}

- (NSString *)levelText {
    return [self valueForKey:@"type"];
}

- (NSString *)name {
    NSString *name = [self valueForKey:@"market_name"];
    if ([name isEqualToString:@""]) {
        name = [self valueForKey:@"name"];
    }

    return name;
}

- (NSString *)origin {
    return nil;
}

- (NSNumber *)originIndex {
    return nil;
}

- (NSNumber *)position {
    NSInteger category = [self.itemCategory integerValue];
    NSInteger position = [[self valueForKey:@"pos"] integerValue];
    return [NSNumber numberWithInteger:category * 100000 + position];
}

- (UIColor *)qualityColor {
    UIColor *color = self.tags[@"Quality"][@"color"];
    if (color == nil) {
        color = [UIColor colorWithRed:0.56 green:0.64 blue:0.73 alpha:1.0];
    }

    return color;
}

- (NSString *)qualityName {
    NSString *qualityName;
    if ([self.inventory.game isSteam]) {
        qualityName = self.tags[@"droprate"][@"value"];
    } else {
        qualityName = self.tags[@"Quality"][@"value"];
    }

    return [qualityName capitalizedStringWithLocale:NSLocale.currentLocale];
}

- (NSNumber *)quantity {
    return [NSNumber numberWithInteger:[[self valueForKey:@"amount"] integerValue]];
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
