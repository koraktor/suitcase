//
//  SCAppDelegate.h
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import <UIKit/UIKit.h>
#import <Crashlytics/Crashlytics.h>

#import "TSMessageView.h"

#import "SCCommunityRequestOperationManager.h"
#import "SCWebApiRequestOperationManager.h"

@interface SCAppDelegate : UIResponder <CrashlyticsDelegate, TSMessageViewProtocol, UIAlertViewDelegate, UIApplicationDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (SCCommunityRequestOperationManager *)communityClient;
+ (SCWebApiRequestOperationManager *)webApiClient;
+ (void)errorWithTitle:(NSString *)title andMessage:(NSString *)message inController:(UIViewController *)controller;

- (void)defaultsChanged:(NSNotification *)notification;

@end
