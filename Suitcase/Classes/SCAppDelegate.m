//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2015, Sebastian Staudt
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "AFNetworkActivityIndicatorManager.h"
#import "FAKFontAwesome.h"
#import "TSMessage.h"
#import "IASKSpecifierValuesViewController.h"

#import "SCCommunityInventory.h"
#import "SCImageCache.h"
#import "SCLanguage.h"

#import "SCAppDelegate.h"

#ifndef __API_KEY__
#define __API_KEY__ nil
#endif

#ifndef __CRASHLYTICS_API_KEY__
#define __CRASHLYTICS_API_KEY__ nil
#endif

@interface SCAppDelegate () {
    NSDictionary *_storedDefaults;
}
@end

@implementation SCAppDelegate

static SCCommunityRequestOperationManager *_communityClient;
static SCWebApiRequestOperationManager *_webApiClient;

+ (SCCommunityRequestOperationManager *)communityClient
{
    if (_communityClient == nil) {
        _communityClient = [[SCCommunityRequestOperationManager alloc] init];
    }

    return _communityClient;
}

+ (void)errorWithMessage:(NSString *)errorMessage
{
#ifdef DEBUG
    NSLog(@"%@", errorMessage);
#endif
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:errorMessage
                                                       delegate:[UIApplication sharedApplication].delegate
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}

+ (void)errorWithTitle:(NSString *)title andMessage:(NSString *)message inController:(UIViewController *)controller {
    NSShadow *iconShadow = [NSShadow new];
    [iconShadow setShadowColor:[UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0]];
    [iconShadow setShadowOffset:CGSizeMake(0.0, 1.0)];

    FAKIcon *warningIcon = [FAKFontAwesome exclamationTriangleIconWithSize:32.0];
    [warningIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    [warningIcon addAttribute:NSShadowAttributeName value:iconShadow];

    [TSMessage showNotificationInViewController:controller
                                          title:title
                                       subtitle:message
                                          image:[warningIcon imageWithSize:CGSizeMake(32.0, 32.0)]
                                           type:TSMessageNotificationTypeError
                                       duration:TSMessageNotificationDurationAutomatic
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                           canBeDismissedByUser:NO];
}

+ (SCWebApiRequestOperationManager *)webApiClient
{
    if (_webApiClient == nil) {
        _webApiClient = [[SCWebApiRequestOperationManager alloc] init];
    }

    return _webApiClient;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"clear_cache"]) {
        [SCImageCache clearImageCache];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"clear_cache"];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef DEBUG
    [Fabric with:@[CrashlyticsKit]];
#endif

    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:5000000 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:cache];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [TSMessage addCustomDesignFromFileWithName:@"TSMessagesDesign.json"];

    [SCImageCache setupImageCacheDirectory];

    UIViewController *masterViewController;
    UINavigationController *navigationController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        masterViewController = [[splitViewController.viewControllers objectAtIndex:0] topViewController];
    } else {
        navigationController = (UINavigationController *)self.window.rootViewController;
        masterViewController = navigationController.topViewController;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAvailableGames" object:nil];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
        if (steamId64 != nil) {
            if ([masterViewController class] == NSClassFromString(@"SCGamesViewController")) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loadGames" object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
            }
        }
    });

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];

        UIImage *barGradientImage = [UIImage imageNamed:@"bar_gradient"];
        [[UINavigationBar appearance] setBackgroundImage:barGradientImage forBarMetrics:UIBarMetricsDefault];
        [[UISearchBar appearance] setBackgroundImage:barGradientImage];
        [[UIToolbar appearance] setBackgroundImage:barGradientImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    } else {
        [[UISearchBar appearance] setBackgroundColor:[UIColor colorWithRed:0.56 green:0.64 blue:0.73 alpha:1.0]];
        [[UISearchBar appearance] setBarTintColor:[UIColor colorWithRed:0.45 green:0.52 blue:0.60 alpha:1.0]];

        CGSize iconSize = CGSizeMake(32.0, 32.0);
        FAKIcon *clearIcon = [FAKFontAwesome timesCircleIconWithSize:16.0];
        [clearIcon setAttributes:@{ NSForegroundColorAttributeName: UIColor.whiteColor }];
        [[UISearchBar appearance] setImage:[clearIcon imageWithSize:iconSize]
                          forSearchBarIcon:UISearchBarIconClear
                                     state:UIControlStateNormal];
        [clearIcon setAttributes:@{ NSForegroundColorAttributeName: UIColor.lightGrayColor }];
        [[UISearchBar appearance] setImage:[clearIcon imageWithSize:iconSize]
                          forSearchBarIcon:UISearchBarIconClear
                                     state:UIControlStateHighlighted];

        FAKIcon *searchIcon = [FAKFontAwesome searchIconWithSize:32.0];
        [searchIcon setAttributes:@{ NSForegroundColorAttributeName: UIColor.whiteColor }];
        [[UISearchBar appearance] setImage:[searchIcon imageWithSize:iconSize]
                          forSearchBarIcon:UISearchBarIconSearch
                                     state:UIControlStateNormal];

        [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];
        [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    }

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    _storedDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)defaultsChanged:(NSNotification *)notification
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:NSUserDefaultsDidChangeNotification
                           object:nil];

    NSUserDefaults *defaults = notification.object;

    if (![[defaults objectForKey:@"show_colors"] isEqual:[_storedDefaults objectForKey:@"show_colors"]]) {
        [defaultCenter postNotificationName:@"showColorsChanged" object:nil];
    }

    if (![[defaults objectForKey:@"sorting"] isEqual:[_storedDefaults objectForKey:@"sorting"]]) {
        [defaultCenter postNotificationName:@"sortInventory" object:nil];
    }

    NSLocale *currentLanguage = [SCLanguage currentLanguage];
    if (![[defaults objectForKey:@"language" ] isEqual:[currentLanguage localeIdentifier]]) {
        [SCLanguage updateLanguage];

        if (![currentLanguage isEqual:[SCLanguage currentLanguage]]) {
            [defaultCenter postNotificationName:kSCLanguageSettingChanged object:nil];

            [SCAbstractInventory.inventories.allValues enumerateObjectsUsingBlock:^(NSDictionary *userInventories, NSUInteger idx, BOOL *stop) {
                [userInventories.allValues enumerateObjectsUsingBlock:^(SCAbstractInventory *inventory, NSUInteger idx, BOOL *stop) {
                    if ([inventory isKindOfClass:[SCCommunityInventory class]]) {
                        [inventory forceOutdated];
                    }
                }];
            }];

            UINavigationController *navigationController;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
                navigationController = splitViewController.viewControllers.lastObject;
            } else {
                navigationController = (UINavigationController *)self.window.rootViewController;
            }

            [navigationController popToRootViewControllerAnimated:NO];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
