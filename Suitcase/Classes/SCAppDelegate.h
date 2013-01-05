//
//  SCAppDelegate.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCAppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow *window;

+ (NSString *)apiKey;

- (void)defaultsChanged:(NSNotification *)notification;
- (void)resolveSteamId;

@end
