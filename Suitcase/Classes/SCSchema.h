//
//  SCSchema.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFJSONRequestOperation.h"

#import "SCInventory.h"

@interface SCSchema : NSObject

@property (strong, readonly) NSDictionary *attributes;
@property (strong, readonly) NSDictionary *effects;
@property (strong, readonly) NSDictionary *items;
@property (strong, readonly) NSDictionary *itemNameMap;
@property (strong, readonly) NSDictionary *itemLevels;
@property (strong, readonly) NSDictionary *itemSets;
@property (strong, readonly) NSArray *killEaterTypes;
@property (strong, readonly) NSArray *origins;
@property (strong, readonly) NSArray *qualities;

+ (NSDictionary *)schemas;
+ (AFJSONRequestOperation *)schemaOperationForInventory:(SCInventory *)inventory
                                            andLanguage:(NSString *)language
                                           andCondition:(NSCondition *)condition;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (id)attributeValueFor:(id)attributeKey andKey:(NSString *)key;
- (NSString *)effectNameForIndex:(NSNumber *)effectIndex;
- (NSNumber *)itemDefIndexForName:(NSString *)itemName;
- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key;
- (NSString *)itemLevelForScore:(NSUInteger)score andLevelType:(NSString *)levelType;
- (NSDictionary *)itemSetForKey:(NSString *)itemSetKey;
- (NSDictionary *)killEaterTypeForIndex:(NSUInteger)typeIndex;
- (NSString *)originNameForIndex:(NSUInteger)originIndex;
- (NSString *)qualityNameForIndex:(NSUInteger)qualityIndex;

@end
