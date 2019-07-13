//
//  SCItemSet.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <Foundation/Foundation.h>

@interface SCItemSet : NSObject

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *name;

+ (instancetype)itemSetWithId:(NSString *)identifier andName:(NSString *)itemSetName andItems:(NSArray *)itemSetItems;

@end
