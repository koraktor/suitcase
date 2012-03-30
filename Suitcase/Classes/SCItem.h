//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCSchema.h"

@interface SCItem : NSObject

@property NSDictionary *dictionary;
@property SCSchema *schema;

- (id)initWithDictionary:(NSDictionary *)aDictionary
               andSchema:(SCSchema *)aSchema;

- (NSNumber *)defindex;
- (NSURL *)imageUrl;
- (NSString *)name;

@end
