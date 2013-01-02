//
//  SCInventory.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <Foundation/Foundation.h>

#import "SCGame.h"
#import "SCSchema.h"

@interface SCInventory : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSArray *itemSections;
@property (strong, nonatomic) SCGame *game;
@property (strong, nonatomic) SCSchema *schema;
@property (nonatomic) BOOL showColors;

- (id)initWithItems:(NSArray *)items
            andGame:(SCGame*)game
          andSchema:(SCSchema *)schema;

- (void)sortItems;

@end
