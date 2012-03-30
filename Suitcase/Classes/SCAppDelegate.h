//
//  SCAppDelegate.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCAppDelegate : UIResponder <UIApplicationDelegate> {
    @public NSNumber *steamId64;
}

@property (strong, nonatomic) NSNumber *steamId64;
@property (strong, nonatomic) UIWindow *window;

+ (NSString *)apiKey;

@end
