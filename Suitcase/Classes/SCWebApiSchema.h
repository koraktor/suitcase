//
//  SCSchema.h
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

@class SCWebApiInventory;

@interface SCWebApiSchema : NSObject <NSCoding>

@property (strong, readonly) NSDictionary *attributes;
@property (strong, readonly) NSDictionary *effects;
@property (strong, readonly) NSDictionary *items;
@property (strong, readonly) NSDictionary *itemNameMap;
@property (strong, readonly) NSDictionary *itemLevels;
@property (strong, readonly) NSDictionary *itemSets;
@property (strong, readonly) NSDictionary *killEaterTypes;
@property (strong, readonly) NSArray *origins;
@property (strong, readonly) NSArray *qualities;
@property (strong, nonatomic) NSDate *timestamp;

+ (void)clearSchemas;
+ (void)restoreSchemas;
+ (NSDictionary *)schemas;
+ (AFHTTPRequestOperation *)schemaOperationForInventory:(SCWebApiInventory *)inventory
                                            andLanguage:(NSLocale *)locale;
+ (void)storeSchema:(SCWebApiSchema *)schema forAppId:(NSNumber *)appId andLanguage:(NSString *)locale;
+ (void)storeSchemas;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (id)attributeValueFor:(id)attributeKey andKey:(NSString *)key;
- (NSString *)effectNameForIndex:(NSNumber *)effectIndex;
- (NSNumber *)itemDefIndexForName:(NSString *)itemName;
- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key;
- (NSString *)itemLevelForScore:(NSNumber *)score
                   andLevelType:(NSString *)levelType;
- (NSDictionary *)itemSetForKey:(NSString *)itemSetKey;
- (NSDictionary *)killEaterTypeForIndex:(NSNumber *)typeIndex;
- (NSString *)originNameForIndex:(NSUInteger)originIndex;
- (NSString *)qualityNameForIndex:(NSNumber *)qualityIndex;

@end
