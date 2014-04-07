//
//  SCItem.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCInventory.h"

@protocol SCItem <NSObject>

- (NSURL *)iconUrl;
- (NSURL *)imageUrl;
- (id<SCInventory>)inventory;
- (NSString *)levelText;
- (NSString *)name;
- (NSString *)origin;
- (NSNumber *)quality;
- (UIColor *)qualityColor;
- (NSString *)qualityName;
- (NSNumber *)quantity;

@end
