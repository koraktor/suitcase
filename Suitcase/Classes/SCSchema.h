//
//  SCSchema.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <Foundation/Foundation.h>

@interface SCSchema : NSObject

@property (strong, readonly) NSDictionary *attributes;
@property (strong, readonly) NSDictionary *items;
@property (strong, readonly) NSArray *origins;
@property (strong, readonly) NSArray *qualities;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (id)attributeValueFor:(id)attributeKey andKey:(NSString *)key;
- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key;
- (NSString *)originNameForIndex:(NSUInteger)originIndex;
- (NSString *)qualityNameForIndex:(NSUInteger)qualityIndex;

@end
