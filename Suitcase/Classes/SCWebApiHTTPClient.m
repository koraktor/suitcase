//
//  SCWebApiHTTPClient.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "SCWebApiHTTPClient.h"

#ifndef __API_KEY__
#define __API_KEY__ nil
#endif

@implementation SCWebApiHTTPClient

- (id)init
{
    NSString *apiUrl = @"http://api.steampowered.com/";
    self = [super initWithBaseURL:[NSURL URLWithString:apiUrl]];

    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setDefaultHeader:@"User-Agent" value:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

    return self;
}

- (AFJSONRequestOperation *)jsonRequestForInterface:(NSString *)interface
                                          andMethod:(NSString *)method
                                         andVersion:(NSUInteger)version
                                     withParameters:(NSDictionary *)parameters
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [params setObject:__API_KEY__ forKey:@"key"];
    NSString *path = [NSString stringWithFormat:@"%@/%@/v%04d", interface, method, version];
    NSURLRequest *request = [self requestWithMethod:@"GET"
                                               path:path
                                         parameters:[params copy]];

#ifdef DEBUG
    NSLog(@"Querying Steam Web API: %@", [[[request URL] absoluteString] stringByReplacingOccurrencesOfString:__API_KEY__ withString:@"SECRET"]);
#endif

    return [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
#ifdef DEBUG
        NSLog(@"Web API request @ %@ succeeded with status code %d", path, response.statusCode);
#endif
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
#ifdef DEBUG
        NSLog(@"Web API request @ %@ failed with status code %d", path, response.statusCode);
#endif
    }];
}

@end
