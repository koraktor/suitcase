//
//  SCCommunityInventory.h
//  Suitcase
//
//  Copyright (c) 2014-2016, Sebastian Staudt
//
//

#import <Foundation/Foundation.h>

#import "SCAbstractInventory.h"
#import "SCInventory.h"

@interface SCCommunityInventory : SCAbstractInventory <SCInventory>

- (void)retry;

@end
