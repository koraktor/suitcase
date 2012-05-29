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
@property (readonly) NSNumber *position;
@property SCSchema *schema;

- (id)initWithDictionary:(NSDictionary *)aDictionary
               andSchema:(SCSchema *)aSchema;

- (NSNumber *)defindex;
- (NSString *)description;
- (NSURL *)imageUrl;
- (NSString *)itemType;
- (NSNumber *)level;
- (NSString *)name;
- (NSString *)origin;
- (NSString *)quality;

- (id)valueForKey:(NSString *)key;

@end
