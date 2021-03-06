//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCAbstractInventory.h"
#import "SCInventory.h"

@class SCWebApiInventory;

#import "SCWebApiSchema.h"

@interface SCWebApiInventory : SCAbstractInventory <SCInventory>

@property (strong, nonatomic) SCWebApiSchema *schema;

@end
