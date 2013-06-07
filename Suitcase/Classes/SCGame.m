//
//  SCGame.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "SCGame.h"

@implementation SCGame

- (id)initWithJSONObject:(NSDictionary *)jsonObject
{
    _appId   = [jsonObject objectForKey:@"appid"];
    NSString *logoUrl = [NSString stringWithFormat:@"http://media.steampowered.com/steamcommunity/public/images/apps/%@/%@.jpg", _appId, [jsonObject objectForKey:@"img_logo_url"]];
    _logoUrl = [NSURL URLWithString:logoUrl];
    _name    = [jsonObject objectForKey:@"name"];

    return self;
}

- (BOOL)isTF2
{
    return [_appId intValue] == 440 || [_appId intValue] == 520;
}

@end
