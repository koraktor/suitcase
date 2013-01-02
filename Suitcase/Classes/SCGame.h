//
//  SCGame.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "DDXMLElement.h"

@interface SCGame : NSObject

@property (readonly) NSNumber *appId;
@property (readonly) NSURL *logoUrl;
@property (readonly) NSString *name;

- (id)initWithXMLElement:(DDXMLElement *)xmlElement;

@end
