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

        for (NSDictionary *descriptionData in [self valueForKey:@"descriptions"]) {
            __block NSString *descriptionText = [descriptionData[@"value"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            if ([descriptionText length] == 0) {
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

        _description = [NSString stringWithString:description];
    }

    return _description;
}

- (BOOL)hasOrigin {
    return NO;
}

- (BOOL)hasQuality {
    return self.qualityName != nil;
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://cdn.steamcommunity.com/economy/image/%@/%@", [self valueForKey:@"icon_url"], kIconSize]];
}

- (NSURL *)imageUrl {
    NSString *url = [self valueForKey:@"icon_url_large"];
    if (url == nil || [url isEqualToString:@""]) {
        url = [self valueForKey:@"icon_url"];
    }

    return [NSURL URLWithString:[NSString stringWithFormat:@"http://cdn.steamcommunity.com/economy/image/%@/%@", url, kImageSize]];
}

- (BOOL)isKillEater {
    return NO;
}

- (NSDictionary *)itemSet {
    return nil;
}

- (NSString *)itemType {
    return [self valueForKey:@"type"];
}

- (NSString *)killEaterDescription {
    return nil;
}

- (NSNumber *)killEaterScore {
    return nil;
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

- (UIColor *)qualityColor {
    return self.tags[@"Quality"][@"color"];
}

- (NSString *)qualityName {
    return self.tags[@"Quality"][@"value"];
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