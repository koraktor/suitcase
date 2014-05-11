//
//  SCWebApiItem.h
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCWebApiInventory.h"
#import "SCItem.h"

@interface SCWebApiItem : NSObject <SCItem>

@property (strong, readonly) NSArray *attributes;
@property NSDictionary *dictionary;
@property (readonly) int equippableClasses;
@property (readonly) int equippedClasses;
@property SCWebApiInventory *inventory;
@property (readonly) NSString *name;
@property (readonly) NSNumber *position;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCWebApiInventory *)anInventory;

- (NSNumber *)defindex;
- (NSURL *)imageUrl;
- (NSDictionary *)itemSet;
- (NSNumber *)level;
- (NSString *)levelText;
- (NSString *)origin;
- (NSNumber *)quantity;

- (id)valueForKey:(NSString *)key;

@end
