//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "AFNetworkActivityIndicatorManager.h"
#import "TSMessage.h"
#import "IASKSpecifierValuesViewController.h"

#import "SCAppDelegate.h"

#ifndef __API_KEY__
#define __API_KEY__ nil
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

+ (SCWebApiRequestOperationManager *)webApiClient
{
    if (_webApiClient == nil) {
        _webApiClient = [[SCWebApiRequestOperationManager alloc] init];
    }

    return _webApiClient;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    UINavigationController *navigationController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        navigationController = ((UISplitViewController *)self.window.rootViewController).viewControllers[0];
    } else {
        navigationController = (UINavigationController *)self.window.rootViewController;
    }

    NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    if (steamId64 == nil) {
        [navigationController.topViewController performSegueWithIdentifier:@"SteamIDForm" sender:self];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:5000000 diskCapacity:50000000 diskPath:nil];
    [NSURLCache setSharedURLCache:cache];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAvailableGames" object:nil];

    [TSMessage addCustomDesignFromFileWithName:@"TSMessagesDesign.json"];

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

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];

        UIImage *barGradientImage = [UIImage imageNamed:@"bar_gradient"];
        [[UINavigationBar appearance] setBackgroundImage:barGradientImage forBarMetrics:UIBarMetricsDefault];
        [[UIToolbar appearance] setBackgroundImage:barGradientImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    } else {
        //[[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.4 alpha:0.5]];

        //[[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.3 alpha:0.5]];
        //[[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.4 alpha:0.5]];
    }

    NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    if (steamId64 != nil) {
        if ([masterViewController class] == NSClassFromString(@"SCGamesViewController")) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadGames" object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
        }
    }

    return YES;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([((UINavigationController *) window.rootViewController).topViewController class] == NSClassFromString(@"SCWikiViewController")) {
            return UIInterfaceOrientationMaskAllButUpsideDown;
        } else {
            return UIInterfaceOrientationMaskPortrait;
        }
    } else {
        return UIInterfaceOrientationMaskLandscape;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
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
        [defaultCenter postNotificationName:@"refreshInventory" object:nil];
    } else if (![[defaults objectForKey:@"sorting"] isEqual:[_storedDefaults objectForKey:@"sorting"]]) {
        [defaultCenter postNotificationName:@"sortInventory" object:nil];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[IASKSpecifierValuesViewController class]]) {
        UITableView *tableView = (UITableView *)viewController.view;
        tableView.backgroundColor = [UIColor colorWithRed:0.3647 green:0.4235 blue:0.4706 alpha:1.0];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
