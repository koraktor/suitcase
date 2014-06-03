//
//  SCTF2Item.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "HexColor.h"

#import "SCTF2Item.h"

typedef NS_ENUM(NSUInteger, SCTF2ItemQuality) {
    SCTF2ItemQualityNormal,
    SCTF2ItemQualityRarity1,
    SCTF2ItemQualityRarity2,
    SCTF2ItemQualityVintage,
    SCTF2ItemQualityRarity3,
    SCTF2ItemQualityRarity4,
    SCTF2ItemQualityUnique,
    SCTF2ItemQualityCommunity,
    SCTF2ItemQualityDeveloper,
    SCTF2ItemQualitySelfmade,
    SCTF2ItemQualityCustomized,
    SCTF2ItemQualityStrange,
    SCTF2ItemQualityCompleted,
    SCTF2ItemQualityHaunted,
    SCTF2ItemQualityCollectors
};

@implementation SCTF2Item

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCWebApiInventory *)anInventory {
    self = [super initWithDictionary:aDictionary andInventory:anInventory];

    _equippableClasses = -1;
    _equippedClasses   = -1;

    return self;
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

- (UIColor *)qualityColor {
    NSInteger itemQuality = [self.quality integerValue];

    switch (itemQuality) {
        case SCTF2ItemQualityRarity1:
            return [UIColor colorWithHexString:@"#4D7455"];

        case SCTF2ItemQualityVintage:
            return [UIColor colorWithHexString:@"#476291"];

        case SCTF2ItemQualityRarity4:
            return [UIColor colorWithHexString:@"#8650AC"];

        case SCTF2ItemQualityUnique:
            return [UIColor colorWithHexString:@"#7D6D00"];

        case SCTF2ItemQualityCommunity:
            return [UIColor colorWithHexString:@"#70B04A"];

        case SCTF2ItemQualityStrange:
            return [UIColor colorWithHexString:@"#CF6A32"];

        case SCTF2ItemQualityHaunted:
            return [UIColor colorWithHexString:@"#38F3AB"];

        default:
            return [super qualityColor];
    }
}

@end
