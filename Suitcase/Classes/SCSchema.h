//
//  SCSchema.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <Foundation/Foundation.h>

@interface SCSchema : NSObject

@property NSDictionary *dictionary;

- (id)initWithArray:(NSArray *)dictionary;

- (id)valueForDefIndex:(NSNumber *)defindex andKey:(NSString *)key;

@end
