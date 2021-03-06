//
//  SCGame.h
//  Suitcase
//
//  Copyright (c) 2013-2016, Sebastian Staudt
//

@interface SCGame : NSObject <NSCoding>

@property (readonly) NSNumber *appId;
@property (readonly) NSURL *logoUrl;
@property (readonly) NSString *name;
@property (readonly) NSArray *itemCategories;

+ (NSArray *)communityInventories;
+ (instancetype)gameWithAppId:(NSNumber *)appId;
+ (void)restoreGames;
+ (instancetype)steamGame;
+ (void)storeGames;
+ (NSArray *)webApiInventories;
- (id)initWithJSONObject:(NSDictionary *)jsonObject;
- (NSComparisonResult)compare:(SCGame *)game;
- (NSString *)logoIdentifier;
- (BOOL)isDota2;
- (BOOL)isSteam;
- (BOOL)isTF2;

@end
