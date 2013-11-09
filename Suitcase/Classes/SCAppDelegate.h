//
//  SCAppDelegate.h
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCWebApiRequestOperationManager.h"

@interface SCAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (SCWebApiRequestOperationManager *)webApiClient;
+ (void)errorWithMessage:(NSString *)errorMessage;

- (void)defaultsChanged:(NSNotification *)notification;

@end
