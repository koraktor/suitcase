//
//  SCItem.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCItem.h"

@implementation SCItem

@synthesize dictionary = _dictionary;
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

- (NSURL *)imageUrl {
    return [NSURL URLWithString:[self.schema valueForDefIndex:self.defindex andKey:@"image_url_large"]];
}

- (NSString *)name {
    return [self.schema valueForDefIndex:self.defindex andKey:@"name"];
}

@end
