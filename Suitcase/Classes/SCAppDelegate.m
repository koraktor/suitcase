//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "AFNetworkActivityIndicatorManager.h"

#import "SCAppDelegate.h"

#ifndef __API_KEY__
#define __API_KEY__ nil
#endif

@interface SCAppDelegate () {
    NSDictionary *_storedDefaults;
}
@end

@implementation SCAppDelegate

@synthesize window = _window;

static SCWebApiHTTPClient *_webApiClient;

+ (void)errorWithMessage:(NSString *)errorMessage
{
#ifdef DEBUG
    NSLog(@"%@", errorMessage);
#endif
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:errorMessage
                               delegate:[UIApplication sharedApplication].delegate
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
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
    navigationController.toolbar.tintColor = UIColor.blackColor;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAvailableGames" object:nil];

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

    if (![[defaults objectForKey:@"SteamID"] isEqual:[_storedDefaults objectForKey:@"SteamID"]]) {
        [self resolveSteamId];
    } else if (![[defaults objectForKey:@"show_colors"] isEqual:[_storedDefaults objectForKey:@"show_colors"]]) {
        [defaultCenter postNotificationName:@"refreshInventory" object:nil];
    } else if (![[defaults objectForKey:@"sorting"] isEqual:[_storedDefaults objectForKey:@"sorting"]]) {
        [defaultCenter postNotificationName:@"sortInventory" object:nil];
    }
}

- (void)resolveSteamId
{
    NSString *steamId = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
    steamId = [steamId stringByReplacingOccurrencesOfString:@"(?:http://)?steamcommunity\\.com/(id|profiles)/"
                                                 withString:@""
                                                    options:NSRegularExpressionSearch
                                                      range:NSMakeRange(0, steamId.length)];
    __block NSNumber *steamId64 = [[[NSNumberFormatter alloc] init] numberFromString:steamId];

    void (^SteamIdFound)() = ^() {
        NSNumber *currentSteamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
        if (![currentSteamId64 isEqual:steamId64]) {
            [[NSUserDefaults standardUserDefaults] setObject:steamId forKey:@"SteamID"];
            [[NSUserDefaults standardUserDefaults] setObject:steamId64 forKey:@"SteamID64"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadGames" object:nil];
        }
    };

    if (steamId64 == nil) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:steamId, @"vanityUrl", nil];
        AFJSONRequestOperation *operation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"ISteamUser"
                                                                                        andMethod:@"ResolveVanityURL"
                                                                                       andVersion:1
                                                                                   withParameters:params];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *steamIdResponse = [responseObject objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                steamId64 = [steamIdResponse objectForKey:@"steamid"];
                SteamIdFound();
            } else {
                NSString *errorMessage = [NSString stringWithFormat:@"Error resolving Steam ID: %@", [steamIdResponse objectForKey:@"message"]];
                [SCAppDelegate errorWithMessage:errorMessage];

                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SteamID"];
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SteamID64"];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [SCAppDelegate errorWithMessage:[error localizedDescription]];
        }];
        [operation start];
    } else {
        SteamIdFound();
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
