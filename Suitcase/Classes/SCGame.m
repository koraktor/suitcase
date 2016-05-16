//
//  SCGame.m
//  Suitcase
//
//  Copyright (c) 2013-2016, Sebastian Staudt
//

#import "SCGame.h"

@implementation SCGame

static NSArray *kSCCommunityInventories;
static NSArray *kSCWebApiInventories;
static NSMutableDictionary *__games;

+ (void)initialize {
    kSCCommunityInventories = @[
        @570,    // Dota 2
        @620,    // Portal 2
        @730,    // Counter-Strike: Global Offensive
        @753,    // Steam
        @4920,   // Natural Selection 2
        @104700, // Super Monday Night Combat
        @205790, // Dota 2 Test
        @207140, // Speed Runners
        @218620, // PAYDAY 2
        @221540, // Defense Grid 2
        @230410, // Warframe
        @238460, // BattleBlock Theater
        @232090, // Killing Floor 2
        @239220, // The Mighty Quest For Epic Loot
        @251970, // Sins of a Dark Age
        @252490, // Rust
        @263920, // Zombie Grinder
        @290340, // Armello
        @295110, // H1Z1: Just Survive
        @304930, // Unturned
        @308080, // Altitude0: Lower & Faster
        @321360, // Primal Carnage: Extinction
        @322330, // Don’t Starve Together
        @375950, // Viridi
        @394690, // Tower Unite
        @433850, // H1Z1: King of the Kill
        @437220, // The Culling
    ];
    kSCWebApiInventories = @[
        @440 // Team Fortress 2
    ];
    __games = [NSMutableDictionary dictionary];
}

+ (NSArray *)communityInventories {
    return kSCCommunityInventories;
}

+ (instancetype)gameWithAppId:(NSNumber *)appId {
    return __games[appId];
}

+ (NSArray *)itemCategoriesForAppId:(NSNumber *)appId {
    if ([appId isEqualToNumber:@753]) {
        return @[@3, @6, @7];
    } else if ([appId isEqualToNumber:@104700]) {
        return @[@2, @3, @13];
    } else if ([@[@251970, @295110, @308080, @321360, @322330] containsObject:appId]) {
        return @[@1];
    } else if ([appId isEqualToNumber:@239220]) {
        return @[@15];
    } else {
        return @[@2];
    }
}

+ (void)restoreGames {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:documentsPath];

    NSString *fileName;
    while (fileName = [dirEnum nextObject]) {
        if ([fileName isEqualToString:@"games"]) {
            __games = [NSKeyedUnarchiver unarchiveObjectWithFile:[documentsPath stringByAppendingPathComponent:fileName]];
#ifdef DEBUG
            NSLog(@"Restored games.");
#endif
            return;
        }
    };
}

+ (instancetype)steamGame
{
    return [[self alloc] initWithAppId:@753
                               andName:@"Steam"
                           andLogoHash:@"ebc73b4e326945ea7eb986d93e2b1aabb291fe7d"];
}

+ (void)storeGames {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *fileName = [NSString stringWithFormat:@"games"];
    NSString *gamesPath = [documentsPath stringByAppendingPathComponent:fileName];

    [NSKeyedArchiver archiveRootObject:__games toFile:gamesPath];

#ifdef DEBUG
    NSLog(@"Stored games.");
#endif
}

+ (NSArray *)webApiInventories {
    return kSCWebApiInventories;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObject
{
    self = [self initWithAppId:jsonObject[@"appid"]
                       andName:jsonObject[@"name"]
                   andLogoHash:jsonObject[@"img_logo_url"]];

    return self;
}

- (id)initWithAppId:(NSNumber *)appId
            andName:(NSString *)name
        andLogoHash:(NSString *)logoHash
{
    _appId = appId;
    NSString *logoUrl = [NSString stringWithFormat:@"http://media.steampowered.com/steamcommunity/public/images/apps/%@/%@.jpg", _appId, logoHash];
    _logoUrl = [NSURL URLWithString:logoUrl];
    _name = name;
    _itemCategories = [SCGame itemCategoriesForAppId:_appId];

    __games[appId] = self;

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

#pragma NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];

    _appId = [aDecoder decodeObjectForKey:@"appId"];
    _itemCategories = [SCGame itemCategoriesForAppId:_appId];
    _logoUrl = [aDecoder decodeObjectForKey:@"logoUrl"];
    _name = [aDecoder decodeObjectForKey:@"name"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_appId forKey:@"appId"];
    [aCoder encodeObject:_logoUrl forKey:@"logoUrl"];
    [aCoder encodeObject:_name forKey:@"name"];
}

@end
