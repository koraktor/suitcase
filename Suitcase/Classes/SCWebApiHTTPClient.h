//
//  SCWebApiHTTPClient.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

@interface SCWebApiHTTPClient : AFHTTPClient

- (AFJSONRequestOperation *)jsonRequestForInterface:(NSString *)interface
                                          andMethod:(NSString *)method
                                         andVersion:(NSUInteger)version
                                     withParameters:(NSDictionary *)parameters;

@end
