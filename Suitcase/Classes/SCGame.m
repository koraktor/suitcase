//
//  SCGame.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
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
    self = [self initWithAppId:jsonObject[@"appid"]
                       andName:jsonObject[@"name"]
                   andLogoHash:jsonObject[@"img_logo_url"]
             andItemCategories:@[@2]];

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

- (BOOL)isTF2
{
    return [_appId intValue] == 440 || [_appId intValue] == 520;
}

- (NSString *)logoIdentifier {
    return [self.appId stringValue];
}

@end
