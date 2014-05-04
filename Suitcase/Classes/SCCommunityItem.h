//
//  SCCommunityItem.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCCommunityInventory.h"
#import "SCItem.h"

@interface SCCommunityItem : NSObject <SCItem>

@property (strong, readonly) NSArray *attributes;
@property NSDictionary *dictionary;
@property (readonly) int equippableClasses;
@property (readonly) int equippedClasses;
@property SCCommunityInventory *inventory;
@property (readonly) NSNumber *itemCategory;
@property (readonly) NSString *name;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCCommunityInventory *)anInventory
         andItemCategory:(NSNumber *)itemCategory;

- (NSURL *)iconUrl;
- (NSURL *)imageUrl;
- (NSDictionary *)itemSet;
- (NSString *)itemType;
- (NSString *)levelText;
- (NSString *)origin;
- (NSNumber *)position;
- (NSNumber *)quantity;

- (id)valueForKey:(NSString *)key;

@end
