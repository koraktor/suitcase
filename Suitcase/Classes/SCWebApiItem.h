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

@property (nonatomic, strong) NSArray *attributes;
@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) SCWebApiInventory *inventory;
@property (nonatomic, strong) NSString *name;

- (id)initWithDictionary:(NSDictionary *)aDictionary
            andInventory:(SCWebApiInventory *)anInventory;

- (void)clearCachedValues;
- (NSNumber *)defindex;
- (NSURL *)imageUrl;
- (NSNumber *)level;
- (NSString *)levelText;
- (NSString *)origin;
- (NSNumber *)quality;
- (NSNumber *)quantity;

- (id)valueForKey:(NSString *)key;

@end
