//
//  SCWebApiAFHTTPRequestOperationManager.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "SCWebApiRequestOperationManager.h"

#ifndef __API_KEY__
#define __API_KEY__ nil
#endif

@implementation SCWebApiRequestOperationManager

- (id)init
{
    NSString *apiUrl = @"https://api.steampowered.com/";
    self = [super initWithBaseURL:[NSURL URLWithString:apiUrl]];

    NSString *userAgent = [NSString stringWithFormat:@"%@ %@ (iOS %@)",
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                           [UIDevice currentDevice].systemVersion];

    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    self.responseSerializer = [AFJSONResponseSerializer serializer];

    return self;
}

- (AFHTTPRequestOperation *)jsonRequestForInterface:(NSString *)interface
                                          andMethod:(NSString *)method
                                         andVersion:(NSUInteger)version
                                     withParameters:(NSDictionary *)parameters
                                            encoded:(BOOL)encoded
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    if (encoded) {
        if (parameters != nil) {
            NSError *error;
            NSData *inputJson = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
            [params setObject:[[NSString alloc] initWithData:inputJson encoding:NSUTF8StringEncoding] forKey:@"input_json"];
        }
    } else {
        [params addEntriesFromDictionary:parameters];
    }

    [params setObject:__API_KEY__ forKey:@"key"];
    NSString *path = [NSString stringWithFormat:@"%@/%@/v%04d", interface, method, version];
    AFHTTPRequestOperation *request = [self GET:path parameters:params success:^(AFHTTPRequestOperation *operation, id response) {
#ifdef DEBUG
        NSLog(@"Web API request @ %@ succeeded with status code %d", path, operation.response.statusCode);
#endif
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef DEBUG
        NSLog(@"Web API request @ %@ failed with status code %d", path, operation.response.statusCode);
#endif
    }];

#ifdef DEBUG
    NSLog(@"Querying Steam Web API: %@", [[[[request request] URL] absoluteString] stringByReplacingOccurrencesOfString:__API_KEY__ withString:@"SECRET"]);
#endif

    return request;
}

@end