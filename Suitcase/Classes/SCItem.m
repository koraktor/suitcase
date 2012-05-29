//
//  SCItem.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCItem.h"

@implementation SCItem

@synthesize dictionary = _dictionary;
@synthesize position = _position;
@synthesize schema = _schema;

- (id)initWithDictionary:(NSDictionary *)aDictionary
               andSchema:(SCSchema *)aSchema {
    self.dictionary = aDictionary;
    self.schema = aSchema;

    return self;
}


- (NSNumber *)defindex {
    return [self.dictionary objectForKey:@"defindex"];
}

- (NSString *)description {
    return [self valueForKey:@"item_description"];
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
            
- (id)valueForKey:(NSString *)key {
    return [self.schema itemValueForDefIndex:self.defindex andKey:key];
}

@end
