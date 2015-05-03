//
//  SCGame.m
//  Suitcase
//
//  Copyright (c) 2013-2015, Sebastian Staudt
//

#import "SCGame.h"

@implementation SCGame

+ (instancetype)steamGame
{
    SCGame *game = [[self alloc] initWithAppId:@753
                                       andName:@"Steam"
                                   andLogoHash:@"ebc73b4e326945ea7eb986d93e2b1aabb291fe7d"
                             andItemCategories:@[@3, @6, @7]];

    return game;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObject
{
    NSNumber *appId = jsonObject[@"appid"];
    NSArray *itemCategories;
    if ([appId isEqualToNumber:@104700]) {
        itemCategories = @[@2, @3, @13];
    } else if ([@[@251970, @308080] containsObject:appId]) {
        itemCategories = @[@1];
    } else if ([appId isEqualToNumber:@239220]) {
        itemCategories = @[@15];
    } else {
        itemCategories = @[@2];
    }

    self = [self initWithAppId:appId
                       andName:jsonObject[@"name"]
                   andLogoHash:jsonObject[@"img_logo_url"]
             andItemCategories:itemCategories];

    return self;
}

- (id)initWithAppId:(NSNumber *)appId
            andName:(NSString *)name
        andLogoHash:(NSString *)logoHash
  andItemCategories:(NSArray *)itemCategories
{
    _appId = appId;
    NSString *logoUrl = [NSString stringWithFormat:@"http://media.steampowered.com/steamcommunity/public/images/apps/%@/%@.jpg", _appId, logoHash];
    _logoUrl = [NSURL URLWithString:logoUrl];
    _name = name;
    _itemCategories = itemCategories;

    return self;
}

- (NSComparisonResult)compare:(SCGame *)game {
    return [self.name compare:game.name];
}

- (NSUInteger)hash
{
    return [_appId unsignedIntegerValue];
}

- (BOOL)isDota2
{
    return [_appId intValue] == 570 || [_appId intValue] == 205790;
}

- (BOOL)isSteam {
    return [_appId intValue] == 753;
}

- (BOOL)isTF2
{
    return [_appId intValue] == 440 || [_appId intValue] == 520;
}

- (NSString *)logoIdentifier {
    return [self.appId stringValue];
}

@end
