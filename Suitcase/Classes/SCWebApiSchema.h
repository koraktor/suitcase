//
//  SCSchema.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

#import "SCWebApiInventory.h"

@interface SCWebApiSchema : NSObject

@property (strong, readonly) NSDictionary *attributes;
@property (strong, readonly) NSDictionary *effects;
@property (strong, readonly) NSDictionary *items;
@property (strong, readonly) NSDictionary *itemNameMap;
@property (strong, readonly) NSDictionary *itemLevels;
@property (strong, readonly) NSDictionary *itemSets;
@property (strong, readonly) NSDictionary *killEaterTypes;
@property (strong, readonly) NSArray *origins;
@property (strong, readonly) NSArray *qualities;

+ (SCWebApiSchema *)brokenSchema;
+ (NSDictionary *)schemas;
+ (AFHTTPRequestOperation *)schemaOperationForInventory:(SCWebApiInventory *)inventory
                                            andLanguage:(NSString *)language;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (id)attributeValueFor:(id)attributeKey andKey:(NSString *)key;
- (NSString *)effectNameForIndex:(NSNumber *)effectIndex;
- (NSNumber *)itemDefIndexForName:(NSString *)itemName;
- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key;
- (NSString *)itemLevelForScore:(NSNumber *)score
                   andLevelType:(NSString *)levelType
                    andItemType:(NSString *)itemType;
- (NSDictionary *)itemSetForKey:(NSString *)itemSetKey;
- (NSDictionary *)killEaterTypeForIndex:(NSNumber *)typeIndex;
- (NSString *)originNameForIndex:(NSUInteger)originIndex;
- (NSString *)qualityNameForIndex:(NSNumber *)qualityIndex;

@end
