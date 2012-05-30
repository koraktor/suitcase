//
//  SCItem.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCItem.h"

@implementation SCItem

@synthesize dictionary = _dictionary;
@synthesize equippedClasses = _equippedClasses;
@synthesize equippableClasses = _equippableClasses;
@synthesize position = _position;
@synthesize schema = _schema;

- (id)initWithDictionary:(NSDictionary *)aDictionary
               andSchema:(SCSchema *)aSchema {
    self.dictionary = aDictionary;
    self.schema = aSchema;

    _equippableClasses = -1;
    _equippedClasses = -1;

    return self;
}


- (NSNumber *)defindex {
    return [self.dictionary objectForKey:@"defindex"];
}

- (NSString *)description {
    return [self valueForKey:@"item_description"];
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

- (NSURL *)imageUrl {
    return [NSURL URLWithString:[self valueForKey:@"image_url_large"]];
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
    return [self.schema originNameForIndex:[originIndex unsignedIntValue]];
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
    return [self.schema qualityNameForIndex:[qualityIndex unsignedIntValue]];
}

- (NSNumber *)quantity {
    return [self.dictionary objectForKey:@"quantity"];
}

- (id)valueForKey:(NSString *)key {
    return [self.schema itemValueForDefIndex:self.defindex andKey:key];
}

@end
