//
//  SCSchema.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCSchema.h"

@implementation SCSchema

@synthesize dictionary;

- (id)initWithArray:(NSArray *)anArray {
    self.dictionary = [NSMutableDictionary dictionaryWithCapacity:[anArray count]];
    [anArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.dictionary setValue:obj forKey:[obj objectForKey:@"defindex"]];
    }];

    return self;
}

- (id)valueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key {
    return [[self.dictionary objectForKey:defindex] objectForKey:key];
}

@end
