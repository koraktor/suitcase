//
//  SCAppDelegate.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "AFNetworkActivityIndicatorManager.h"
#import "FAKFontAwesome.h"
#import "IASKSpecifierValuesViewController.h"

#import "SCCommunityInventory.h"
#import "SCImageCache.h"
#import "SCLanguage.h"
#import "SCWebApiSchema.h"

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

NSString *const kSCUsageReportingQuestionTitle = @"kSCUsageReportingQuestionTitle";
NSString *const kSCUsageReportingQuestionDescription = @"kSCUsageReportingQuestionDescription";

static SCCommunityRequestOperationManager *_communityClient;
static SCWebApiRequestOperationManager *_webApiClient;

+ (SCCommunityRequestOperationManager *)communityClient
{
    if (_communityClient == nil) {
        _communityClient = [[SCCommunityRequestOperationManager alloc] init];
    }

    return _communityClient;
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

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [SCWebApiSchema storeSchemas];
    [SCWebApiSchema clearSchemas];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];

    [self clearCaches];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:5000000 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:cache];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [TSMessage addCustomDesignFromFileWithName:@"TSMessagesDesign.json"];
    [TSMessage setDelegate:self];

    [SCImageCache setupImageCacheDirectory];
    [SCWebApiSchema restoreSchemas];
    [SCGame restoreGames];
    [SCAbstractInventory restoreInventories];

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

    [self configureUsageReportingInViewController:navigationController];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadAvailableGames" object:nil];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
        if (steamId64 != nil) {
            if ([steamId64 isKindOfClass:[NSString class]]) {
                [[NSUserDefaults standardUserDefaults] setObject:[[NSNumberFormatter new] numberFromString:steamId64] forKey:@"SteamID64"];
            }

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

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self clearCaches];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    _storedDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

    [SCWebApiSchema storeSchemas];
    [SCGame storeGames];
    [SCAbstractInventory storeInventories];
}

- (void)clearCaches
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"clear_image_cache"]) {
        [SCImageCache clearImageCache];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"clear_image_cache"];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"clear_data_cache"]) {
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:documentsPath];

        NSString *fileName;
        while (fileName = [dirEnum nextObject]) {
            [[NSFileManager defaultManager] removeItemAtPath:[documentsPath stringByAppendingPathComponent:fileName]
                                                       error:nil];
        }
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"clear_data_cache"];
    }
}

- (void)configureUsageReportingInViewController:(UIViewController *)viewController {
    NSNumber *usageReporting = [[NSUserDefaults standardUserDefaults] objectForKey:@"usage_reporting"];

    if (usageReporting == nil) {
#ifdef DEBUG
        NSLog(@"Usage reporting is not yet configured…");
#endif

        usageReporting = @1;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"usage_reporting"];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            UIViewController *c = viewController;
            while (c.childViewControllers.lastObject != nil) {
                c = c.childViewControllers.lastObject;
            }
            while (c.presentedViewController != nil) {
                c = c.presentedViewController;
            }

            NSString *settingsName = [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] localizedStringForKey:@"Settings" value:@"" table:nil];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [TSMessage showNotificationInViewController:c
                                                      title:NSLocalizedString(kSCUsageReportingQuestionTitle, kSCUsageReportingQuestionTitle)
                                                   subtitle:NSLocalizedString(kSCUsageReportingQuestionDescription, kSCUsageReportingQuestionDescription)
                                                      image:nil
                                                       type:TSMessageNotificationTypeMessage
                                                   duration:8
                                                   callback:nil
                                                buttonTitle:settingsName
                                             buttonCallback:^(void) {
                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                             }
                                                 atPosition:TSMessageNotificationPositionTop
                                       canBeDismissedByUser:YES];
            });
        });


    }

    if ([usageReporting boolValue]) {
#ifdef DEBUG
        NSLog(@"Usage reporting is enabled.");
#endif

        CrashlyticsKit.delegate = self;
        [Fabric with:@[[Crashlytics class]]];
    }
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

#pragma mark Crashlytics Delegate

- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report
                                 completionHandler:(void (^)(BOOL submit))completionHandler {
#ifdef DEBUG
    NSLog(@"Detected an error report…");
#endif

    BOOL usageReporting = [[NSUserDefaults standardUserDefaults] boolForKey:@"usage_reporting"];

#ifdef DEBUG
    NSLog(@"Error report will %@be sent%@", usageReporting ? @"" : @"NOT ", usageReporting ? @"…" : @".");
#endif
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        completionHandler(usageReporting);
    }];
}

#pragma mark TSMessage Delegate

- (void)customizeMessageView:(TSMessageView *)messageView {
    for (UIView *subview in messageView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            CALayer *buttonLayer = subview.layer;
            buttonLayer.borderColor = [[UIColor colorWithRed:0.875f green:0.882f blue:0.894f alpha:1.0f] CGColor];
            buttonLayer.borderWidth = 1.0f;
            buttonLayer.cornerRadius = 8.0f;
            buttonLayer.masksToBounds = NO;
            buttonLayer.shadowColor = [[UIColor colorWithRed: 0.263f green: 0.267f blue: 0.271f alpha: 1.0f] CGColor];
            buttonLayer.shadowOffset = CGSizeMake(0.0f, 1.0f);
            buttonLayer.shadowOpacity = 1.0f;
            buttonLayer.shadowRadius = 1.0f;
        }
    }
}

@end
