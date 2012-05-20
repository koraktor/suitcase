//
//  SCSchema.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <Foundation/Foundation.h>

@interface SCSchema : NSObject

@property NSDictionary *attributes;
@property NSDictionary *items;
@property NSArray *origins;
@property NSArray *qualities;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (id)itemValueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key;
- (NSString *)originNameForIndex:(NSUInteger)originIndex;
- (NSString *)qualityNameForIndex:(NSUInteger)qualityIndex;

@end
