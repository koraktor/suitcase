//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "AFNetworkActivityIndicatorManager.h"
#import "FontAwesomeKit.h"
#import "TSMessage.h"

#import "SCAppDelegate.h"

#ifndef __API_KEY__
#define __API_KEY__ nil
#endif

@interface SCAppDelegate () {
    NSDictionary *_storedDefaults;
}
@end

@implementation SCAppDelegate

static SCWebApiHTTPClient *_webApiClient;

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

+ (SCWebApiHTTPClient *)webApiClient
{
    if (_webApiClient == nil) {
        _webApiClient = [[SCWebApiHTTPClient alloc] init];
    }

    return _webApiClient;
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
        [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
        navigationController = (UINavigationController *)self.window.rootViewController;
        masterViewController = navigationController.topViewController;
    }

    UIImage *barGradientImage = [UIImage imageNamed:@"bar_gradient"];
    [[UINavigationBar appearance] setBackgroundImage:barGradientImage forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:barGradientImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    if (steamId64 == nil) {
        [masterViewController performSegueWithIdentifier:@"SteamIDForm" sender:self];
    } else {
        if ([masterViewController class] == NSClassFromString(@"SCGamesViewController")) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadGames" object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resolveSteamId)
                                                 name:@"resolveSteamId"
                                               object:nil];

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
