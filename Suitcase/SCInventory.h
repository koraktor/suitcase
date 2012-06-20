//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCSchema.h"

@interface SCInventory : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSArray *itemSections;
@property (strong, nonatomic) SCSchema *schema;

- (id)initWithItems:(NSArray *)items andSchema:(SCSchema *)schema;

- (void)sortItems;

@end
