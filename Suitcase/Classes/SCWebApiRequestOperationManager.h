//
//  SCWebApiAFHTTPRequestOperationManager.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "AFHTTPRequestOperationManager.h"

@interface SCWebApiRequestOperationManager : AFHTTPRequestOperationManager

- (AFHTTPRequestOperation *)jsonRequestForInterface:(NSString *)interface
                                          andMethod:(NSString *)method
                                         andVersion:(NSUInteger)version
                                     withParameters:(NSDictionary *)parameters
                                            encoded:(BOOL)encoded;

@end
