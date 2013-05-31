//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "AFNetworkActivityIndicatorManager.h"
#import "FontAwesomeKit.h"
#import "YRDropdownView.h"

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

    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAvailableGames" object:nil];

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
        } else {
            UIViewController *modal = [[[[[self window] rootViewController] presentedViewController] childViewControllers] objectAtIndex:0];
            if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
                [modal dismissModalViewControllerAnimated:YES];
            }
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
                NSString *errorMessage = [NSString stringWithFormat:@"An error occured while resolving the Steam ID: %@", [steamIdResponse objectForKey:@"message"]];

                NSDictionary *iconAttributes = @{
                    FAKImageAttributeForegroundColor: [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],
                    FAKImageAttributeShadow: @{
                        FAKShadowAttributeBlur: @(1.0),
                        FAKShadowAttributeColor: [UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0],
                        FAKShadowAttributeOffset: [NSValue valueWithCGSize:CGSizeMake(3.0, 3.0)]
                    }
                };
                UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 48.0, 48.0)];
                image.image = [FontAwesomeKit imageForIcon:FAKIconWarningSign
                                                 imageSize:CGSizeMake(48.0, 48.0)
                                                  fontSize:46
                                                attributes:iconAttributes];

                YRDropdownView *errorView = [YRDropdownView dropdownInView:[((UIView *)[self.window.rootViewController.presentedViewController.view.subviews objectAtIndex:0]).subviews objectAtIndex:0]
                                                                     title:@"Not found"
                                                                    detail:errorMessage
                                                             accessoryView:image
                                                                  animated:YES];
                [errorView setBackgroundColors:@[
                    [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0],
                    [UIColor colorWithRed:0.4 green:0.0 blue:0.0 alpha:1.0]
                ]];
                [errorView setTextColor:[UIColor lightGrayColor]];
                [errorView setTitleTextColor:[UIColor whiteColor]];
                [errorView setTitleTextShadowColor:[UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0]];
                [errorView setHideAfter:5.0];
                [YRDropdownView presentDropdown:errorView];

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
