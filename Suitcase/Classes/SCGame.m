//
//  SCGame.m
//  Suitcase
//
//  Copyright (c) 2013-2015, Sebastian Staudt
//

#import "SCGame.h"

@implementation SCGame

static NSArray *kSCNonDiscoverableInventories;
static NSArray *kSCWebApiInventories;

+ (void)initialize {
    kSCNonDiscoverableInventories = @[
        @753,    // Steam
        @104700, // Super Monday Night Combat
        @218620, // PAYDAY 2
        @230410, // Warframe
        @232090, // Killing Floor 2
        @239220, // The Mighty Quest For Epic Loot
        @251970, // Sins of a Dark Age
        @252490, // Rust
        @295110, // H1Z1: Just Survive
        @304930, // Unturned
        @308080, // Altitude0: Lower & Faster
        @321360, // Primal Carnage: Extinction
        @375950, // Viridi
    ];
    kSCWebApiInventories = @[
        @440 // Team Fortress 2
    ];
}

+ (NSArray *)nonDiscoverableInventories {
    return kSCNonDiscoverableInventories;
}

+ (instancetype)steamGame
{
    SCGame *game = [[self alloc] initWithAppId:@753
                                       andName:@"Steam"
                                   andLogoHash:@"ebc73b4e326945ea7eb986d93e2b1aabb291fe7d"
                             andItemCategories:@[@3, @6, @7]];

    return game;
}

+ (NSArray *)webApiInventories {
    return kSCWebApiInventories;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObject
{
    NSNumber *appId = jsonObject[@"appid"];
    NSArray *itemCategories;
    if ([appId isEqualToNumber:@104700]) {
        itemCategories = @[@2, @3, @13];
    } else if ([@[@251970, @295110, @308080, @321360] containsObject:appId]) {
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
