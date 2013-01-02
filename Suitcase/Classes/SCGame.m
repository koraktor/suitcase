//
//  SCGame.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "SCGame.h"

@implementation SCGame

@synthesize appId = _appId;
@synthesize logoUrl = _logoUrl;
@synthesize name = _name;

- (id)initWithXMLElement:(DDXMLElement *)xmlElement
{
    _appId   = [NSNumber numberWithInt:[[[[xmlElement elementsForName:@"appID"] objectAtIndex:0] stringValue] intValue]];
    _logoUrl = [NSURL URLWithString:[[[xmlElement elementsForName:@"logo"] objectAtIndex:0] stringValue]];
    _name    = [[[xmlElement elementsForName:@"name"] objectAtIndex:0] stringValue];

    return self;
}

- (BOOL)isTF2
{
    return [_appId intValue] == 440 || [_appId intValue] == 520;
}

@end
