//
//  SCItemQuality.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCItem.h"

@interface SCItemQuality : NSObject

+ (SCItemQuality *)itemQualityFromItem:(id <SCItem>)item;

@property UIColor *color;
@property NSString *name;

@end
