//
//  SCCommunityRequestOperationManager.m
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//
//

#import "SCLanguage.h"

#import "SCCommunityRequestOperationManager.h"

@implementation SCCommunityRequestOperationManager

- (id)init
{
    NSString *communityUrl = @"https://steamcommunity.com/";
    self = [super initWithBaseURL:[NSURL URLWithString:communityUrl]];

    NSString *userAgent = [NSString stringWithFormat:@"%@ %@ (iOS %@)",
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                           [UIDevice currentDevice].systemVersion];

    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];

    self.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

    return self;
}

- (AFHTTPRequestOperation *)jsonRequestForSteamId64:(NSNumber *)steamId64
                                            andGame:(SCGame *)game
                                    andItemCategory:(NSNumber *)itemCategory
{
    NSLocale *preferredLanguage = [SCLanguage currentLanguage];
    NSDictionary *params = @{ @"l": [[[NSLocale localeWithLocaleIdentifier:@"en-US"] displayNameForKey:NSLocaleIdentifier value:preferredLanguage.localeIdentifier] lowercaseString] };
    NSString *path = [NSString stringWithFormat:@"profiles/%@/inventory/json/%@/%@", steamId64, game.appId, itemCategory];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
    AFHTTPRequestOperation *request = [self GET:path parameters:params success:^(AFHTTPRequestOperation *operation, id response) {
#ifdef DEBUG
        NSLog(@"Web API request @ %@ succeeded with status code %ld", path, (long) operation.response.statusCode);
#endif
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef DEBUG
        NSLog(@"Web API request @ %@ failed with status code %ld", path, (long) operation.response.statusCode);
#endif
    }];
    ((NSMutableURLRequest *)request.request).timeoutInterval = 30;

#ifdef DEBUG
    NSLog(@"Querying Steam Community: %@", request.request.URL.absoluteString);
#endif

    return request;
}

@end
