//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCSchema.h"

@interface SCItem : NSObject

@property (strong, readonly) NSArray *attributes;
@property NSDictionary *dictionary;
@property (readonly) int equippableClasses;
@property (readonly) int equippedClasses;
@property (readonly) NSNumber *position;
@property SCSchema *schema;

- (id)initWithDictionary:(NSDictionary *)aDictionary
               andSchema:(SCSchema *)aSchema;

- (NSNumber *)defindex;
- (NSString *)description;
- (NSURL *)iconUrl;
- (NSURL *)imageUrl;
- (NSDictionary *)itemSet;
- (NSString *)itemType;
- (NSNumber *)level;
- (NSString *)name;
- (NSString *)origin;
- (NSString *)quality;
- (NSNumber *)quantity;

- (id)valueForKey:(NSString *)key;

@end
