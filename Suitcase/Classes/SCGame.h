//
//  SCGame.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

@interface SCGame : NSObject

@property (readonly) NSNumber *appId;
@property (readonly) NSURL *logoUrl;
@property (readonly) NSString *name;
@property (readonly) NSArray *itemCategories;

+ (instancetype)steamGame;
- (id)initWithJSONObject:(NSDictionary *)jsonObject;
- (BOOL)isTF2;

@end
