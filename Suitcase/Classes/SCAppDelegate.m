//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"

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

+ (NSString *)apiKey {
    return __API_KEY__;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    
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
        if ([((UINavigationController *) window.rootViewController).topViewController isMemberOfClass:[SCWikiViewController class]]) {
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
        NSURL *steamIdUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001?vanityurl=%@&key=%@", steamId, [SCAppDelegate apiKey]]];
#ifdef DEBUG
        NSLog(@"Resolving 64bit Steam ID from: %@", steamIdUrl);
#endif
        __unsafe_unretained __block ASIHTTPRequest *steamIdRequest = [ASIHTTPRequest requestWithURL:steamIdUrl];
        [steamIdRequest setCompletionBlock:^{
            NSError *error = nil;
            NSDictionary *steamIdResponse = [[NSJSONSerialization JSONObjectWithData:[steamIdRequest responseData] options:0 error:&error] objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                steamId64 = [steamIdResponse objectForKey:@"steamid"];
                SteamIdFound();
            } else {
                NSString *errorMsg = [NSString stringWithFormat:@"Error resolving Steam ID: %@", [steamIdResponse objectForKey:@"message"]];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        }];
        [steamIdRequest setFailedBlock:^{
            NSError *error = [steamIdRequest error];
            NSString *errorMessage;
            if (error == nil) {
                errorMessage = [steamIdRequest responseStatusMessage];
            } else {
                errorMessage = [error localizedDescription];
            }
            NSLog(@"Error resolving Steam ID: %@", errorMessage);
            NSString *errorMsg = [NSString stringWithFormat:@"Error resolving Steam ID: %@", errorMessage];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SteamID"];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SteamID64"];
        }];

        [steamIdRequest startSynchronous];
    } else {
        SteamIdFound();
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
