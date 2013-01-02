//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCInventory.h"

@interface SCItem : NSObject

@property (strong, readonly) NSArray *attributes;
@property NSDictionary *dictionary;
@property (readonly) int equippableClasses;
@property (readonly) int equippedClasses;
@property SCInventory *inventory;
@property (readonly) NSNumber *position;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCInventory *)anInventory;

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
