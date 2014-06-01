//
//  SCItemSet.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemSet.h"

@implementation SCItemSet

static NSMutableDictionary *__itemSets;

+ (void)initialize {
    __itemSets = [NSMutableDictionary dictionary];
}

+ (instancetype)itemSetWithId:(NSString *)identifier andName:(NSString *)itemSetName andItems:(NSArray *)itemSetItems {
    SCItemSet *itemSet = [self itemSetWithId:identifier];

    if (itemSet == nil) {
        itemSet = [[self alloc] initWithName:itemSetName andItems:itemSetItems];
        __itemSets[identifier] = itemSet;
    }

    return itemSet;
}

+ (instancetype)itemSetWithId:(NSString *)identifier {
    return __itemSets[identifier];
}

- (instancetype)initWithName:(NSString *)itemSetName andItems:(NSArray *)itemSetItems {
    self = [self init];

    self.items = [NSArray arrayWithArray:itemSetItems];
    self.name = itemSetName;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (%lu items)", self.name, (unsigned long)self.items.count];
}

@end
