//
//  SCDota2Item.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "HexColor.h"

#import "SCDota2Item.h"

typedef NS_ENUM(NSUInteger, SCDota2ItemQuality) {
    SCDota2ItemQualityNormal,
    SCDota2ItemQualityGenuine,
    SCDota2ItemQualityVintage,
    SCDota2ItemQualityUnusual,
    SCDota2ItemQualityUnique,
    SCDota2ItemQualityCommunity,
    SCDota2ItemQualityDeveloper,
    SCDota2ItemQualitySelfmade,
    SCDota2ItemQualityCustomized,
    SCDota2ItemQualityStrange,
    SCDota2ItemQualityCompleted,
    SCDota2ItemQualityHaunted,
    SCDota2ItemQualityTournament,
    SCDota2ItemQualityFavored,
    SCDota2ItemQualityAscendant,
    SCDota2ItemQualityAutographed,
    SCDota2ItemQualityLegacy,
    SCDota2ItemQualityExalted,
    SCDota2ItemQualityFrozen,
    SCDota2ItemQualityCorrupted,
    SCDota2ItemQualityLucky
};

@implementation SCDota2Item

- (UIColor *)qualityColor {
    NSInteger itemQuality = [self.quality integerValue];

    switch (itemQuality) {
        case SCDota2ItemQualityGenuine:
            return [UIColor colorWithHexString:@"#4D7455"];

        case SCDota2ItemQualityVintage:
            return [UIColor colorWithHexString:@"#476291"];

        case SCDota2ItemQualityUnusual:
            return [UIColor colorWithHexString:@"#8650AC"];

        case SCDota2ItemQualityUnique:
            return [UIColor colorWithHexString:@"#D2D2D2"];

        case SCDota2ItemQualitySelfmade:
            return [UIColor colorWithHexString:@"#70B04A"];

        case SCDota2ItemQualityStrange:
            return [UIColor colorWithHexString:@"#CF6A32"];

        case SCDota2ItemQualityHaunted:
            return [UIColor colorWithHexString:@"#8650AC"];

        case SCDota2ItemQualityTournament:
            return [UIColor colorWithHexString:@"#8650AC"];

        case SCDota2ItemQualityAscendant:
            return [UIColor colorWithHexString:@"#EB4B4B"];

        case SCDota2ItemQualityAutographed:
            return [UIColor colorWithHexString:@"#ADE55C"];

        case SCDota2ItemQualityFrozen:
            return [UIColor colorWithHexString:@"#4682B4"];

        case SCDota2ItemQualityCorrupted:
            return [UIColor colorWithHexString:@"#A52A2A"];

        case SCDota2ItemQualityLucky:
            return [UIColor colorWithHexString:@"#32CD32"];

        default:
            return [super qualityColor];
    }
}

@end
