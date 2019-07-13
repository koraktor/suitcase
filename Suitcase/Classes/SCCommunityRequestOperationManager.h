//
//  SCCommunityRequestOperationManager.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//
//

#import "AFHTTPRequestOperationManager.h"

#import "SCGame.h"

@interface SCCommunityRequestOperationManager : AFHTTPRequestOperationManager

- (AFHTTPRequestOperation *)jsonRequestForSteamId64:(NSNumber *)steamId64
                                            andGame:(SCGame *)game
                                    andItemCategory:(NSNumber *)itemCategory;

@end
