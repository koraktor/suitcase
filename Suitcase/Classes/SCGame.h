//
//  SCGame.h
//  Suitcase
//
//  Copyright (c) 2013-2015, Sebastian Staudt
//

@interface SCGame : NSObject

@property (readonly) NSNumber *appId;
@property (readonly) NSURL *logoUrl;
@property (readonly) NSString *name;
@property (readonly) NSArray *itemCategories;

+ (NSArray *)nonDiscoverableInventories;
+ (NSArray *)nonWebApiInventories;
+ (instancetype)steamGame;
- (id)initWithJSONObject:(NSDictionary *)jsonObject;
- (NSComparisonResult)compare:(SCGame *)game;
- (NSString *)logoIdentifier;
- (BOOL)isDota2;
- (BOOL)isSteam;
- (BOOL)isTF2;

@end
