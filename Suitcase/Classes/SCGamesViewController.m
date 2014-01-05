//
//  SCGamesViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "IASKSettingsReader.h"
#import "TSMessage.h"

#import "SCAppDelegate.h"
#import "SCGame.h"
#import "SCInventory.h"
#import "SCInventoryCell.h"
#import "SCSteamIdFormController.h"

#import "SCGamesViewController.h"

@interface SCGamesViewController () {
    NSArray *_availableGames;
    NSLock *_availableGamesLock;
    SCInventory *_currentInventory;
    NSArray *_games;
    NSLock *_gamesLock;
    NSArray *_inventories;
    SCInventory *_lastInventory;
}
@end

@implementation SCGamesViewController

const NSInteger kSCAvailableGamesErrorView = 0;
NSString *const kSCAvailableGamesErrorMessage = @"kSCAvailableGamesErrorMessage";
NSString *const kSCAvailableGamesErrorTitle   = @"kSCAvailableGamesErrorTitle";
const NSInteger kSCGamesErrorView = 1;
NSString *const kSCGamesErrorMessage     = @"kSCGamesErrorMessage";
NSString *const kSCGamesErrorTitle       = @"kSCGamesErrorTitle";
NSString *const kSCSchemaIsLoading       = @"kSCSchemaIsLoading";
NSString *const kSCSchemaIsLoadingDetail = @"kSCSchemaIsLoadingDetail";

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kSCAvailableGamesErrorView:
            [self loadAvailableGames];
            break;
        case kSCGamesErrorView:
            if (buttonIndex == 1) {
                [self loadGames];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SteamID64"];
                [self performSegueWithIdentifier:@"SteamIDForm" sender:self];
            }
            break;
    }
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadAvailableGames)
                                                 name:@"loadAvailableGames"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadGames)
                                                 name:@"loadGames"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadSchemaStarted)
                                                 name:@"loadSchemaStarted"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadSchemaFinished)
                                                 name:@"loadSchemaFinished"
                                               object:nil];

    _availableGamesLock = [[NSLock alloc] init];
    _gamesLock = [[NSLock alloc] init];

    FAKIcon *userIcon = [FAKFontAwesome userIconWithSize:0.0];
    self.navigationItem.leftBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [userIcon characterCode]];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                         forState:UIControlStateNormal];
    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];

    FAKIcon *wrenchIcon = [FAKFontAwesome wrenchIconWithSize:0.0];
    self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [wrenchIcon characterCode]];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                         forState:UIControlStateNormal];
    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];

    [super awakeFromNib];
}

- (void)loadAvailableGames
{
    AFJSONRequestOperation *apiListOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"ISteamWebAPIUtil"
                                                                                           andMethod:@"GetSupportedAPIList"
                                                                                          andVersion:1
                                                                                      withParameters:nil
                                                                                             encoded:NO];
    [apiListOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *apiListResponse = [responseObject objectForKey:@"apilist"];
        NSArray *interfaces = [apiListResponse objectForKey:@"interfaces"];
        _availableGames = [NSMutableArray array];
        [interfaces enumerateObjectsUsingBlock:^(NSDictionary *interface, NSUInteger idx, BOOL *stop) {
            NSString *interfaceName = [interface valueForKey:@"name"];
            if ([interfaceName hasPrefix:@"IEconItems_"]) {
                NSNumber *appId = [NSNumber numberWithInt:[[interfaceName stringByReplacingCharactersInRange:NSMakeRange(0, 11) withString:@""] intValue]];
                [(NSMutableArray *)_availableGames addObject:appId];
            }
        }];
        _availableGames = [_availableGames copy];
        [_availableGamesLock unlock];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCAvailableGamesErrorMessage, kSCAvailableGamesErrorMessage), [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]];
#ifdef DEBUG
        NSLog(@"%@", errorMessage);
#endif
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kSCAvailableGamesErrorTitle, kSCAvailableGamesErrorTitle)
                                                            message:errorMessage
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Retry", @"Retry")
                                                  otherButtonTitles:nil];
        alertView.tag = kSCAvailableGamesErrorView;
        [alertView show];
    }];
    [_availableGamesLock lock];
    [apiListOperation start];
}

- (void)loadGames
{
    _inventories = nil;
    [self.tableView reloadData];

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [modal dismissModalViewControllerAnimated:YES];
    }

    [NSThread detachNewThreadSelector:@selector(doLoadGames) toTarget:self withObject:nil];
}

- (void)doLoadGames
{
    [_availableGamesLock lock];

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSDictionary *params = @{
        @"appids_filter": _availableGames,
        @"steamId": steamId64,
        @"include_appinfo": @1,
        @"include_played_free_games": @1
    };

    [_availableGamesLock unlock];

    AFJSONRequestOperation *gamesOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"IPlayerService"
                                                                                         andMethod:@"GetOwnedGames"
                                                                                        andVersion:1
                                                                                    withParameters:params
                                                                                           encoded:YES];
    [gamesOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *gamesResponse = [responseObject objectForKey:@"response"];
        NSArray *games = [gamesResponse objectForKey:@"games"];

        NSMutableArray *gameObjects = [NSMutableArray arrayWithCapacity:[(NSNumber *)[gamesResponse objectForKey:@"game_count"] unsignedIntegerValue]];
        for (NSDictionary *game in games) {
            [gameObjects addObject:[[SCGame alloc] initWithJSONObject:game]];
        }

        [_gamesLock unlock];

        [NSThread detachNewThreadSelector:@selector(populateGames:)
                                 toTarget:self
                               withObject:[gameObjects copy]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCGamesErrorMessage, kSCGamesErrorMessage), [NSHTTPURLResponse localizedStringForStatusCode:operation.response.statusCode]];
#ifdef DEBUG
        NSLog(@"%@", errorMessage);
#endif
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kSCGamesErrorTitle, kSCGamesErrorTitle)
                                                            message:errorMessage
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                  otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil];
        alertView.tag = kSCGamesErrorView;
        [alertView show];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [_gamesLock lock];
        [gamesOperation start];
    });
}

- (void)populateInventories
{
    NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];

    BOOL skipEmptyInventories;
    NSNumber *rawSkipEmptyInventories = [[NSUserDefaults standardUserDefaults] valueForKey:@"skip_empty_inventories"];
    if (rawSkipEmptyInventories == nil) {
        skipEmptyInventories = YES;
    } else {
        skipEmptyInventories = [rawSkipEmptyInventories boolValue];
    }

    _inventories = [NSMutableArray array];
    NSArray *inventories = [[[SCInventory inventories] valueForKeyPath:steamId64] allValues];
    [inventories enumerateObjectsUsingBlock:^(SCInventory *inventory, NSUInteger idx, BOOL *stop) {
        if (![inventory isSuccessful] && ![inventory temporaryFailed]) {
            return;
        }
        if (skipEmptyInventories && [inventory isEmpty]) {
            return;
        }
        [(NSMutableArray *)_inventories addObject:inventory];
    }];
    _inventories = [_inventories sortedArrayUsingComparator:^NSComparisonResult(SCInventory* inv1, SCInventory *inv2) {
        return [inv1.game.name compare:inv2.game.name];
    }];

#ifdef DEBUG
    NSLog(@"Loaded %d inventories for user %@.", [_inventories count], steamId64);
#endif

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];

        if ([_inventories count] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    });
}

- (void)populateGames:(NSArray *)games
{
    _games = [NSMutableArray array];
    [games enumerateObjectsUsingBlock:^(SCGame *game, NSUInteger idx, BOOL *stop) {
        if ([_availableGames containsObject:game.appId]) {
            [(NSMutableArray *)_games addObject:game];
        }
    }];
    _games = [_games sortedArrayUsingComparator:^NSComparisonResult(SCGame *game1, SCGame *game2) {
        return [game1.name compare:game2.name];
    }];

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];

#ifdef DEBUG
    NSLog(@"Loaded %d games for user %@.", [_games count], steamId64);
#endif

    [SCInventory setInventoriesToLoad:[_games count]];
    NSCondition *inventoriesCondition = [[NSCondition alloc] init];

    for (SCGame *game in _games) {
        NSOperation *inventoryOperation = [SCInventory inventoryForSteamId64:steamId64
                                                                     andGame:game
                                                                andCondition:inventoriesCondition];
        if (inventoryOperation != nil) {
            [inventoryOperation start];
        }
    }

    [inventoriesCondition lock];
    while ([SCInventory inventoriesToLoad] > 0) {
        [inventoriesCondition wait];
    }

#ifdef DEBUG
    NSLog(@"All inventories loaded");
#endif

    [self populateInventories];

    [inventoriesCondition unlock];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showInventory"]) {
        SCInventoryViewController *inventoryController = segue.destinationViewController;
        if (_lastInventory == _currentInventory && ![_lastInventory outdated]) {
            inventoryController.inventory = _lastInventory;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadInventory" object:nil];
            return;
        }
        if ([_currentInventory temporaryFailed] || [_currentInventory outdated]) {
            NSCondition *reloadCondition = [[NSCondition alloc] init];
            [_currentInventory reloadWithCondition:reloadCondition];

            [SCInventory setInventoriesToLoad:1];
            [reloadCondition lock];
            while ([SCInventory inventoriesToLoad] > 0) {
                [reloadCondition wait];
            }
            [reloadCondition unlock];
            [self populateInventories];
            [self.tableView reloadData];
        }
        inventoryController.inventory = _lastInventory = _currentInventory;
    } else if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        IASKAppSettingsViewController *settingsController = (IASKAppSettingsViewController *)[navigationController.childViewControllers objectAtIndex:0];
        settingsController.title = NSLocalizedString(@"Settings", @"Settings");
        settingsController.delegate = self;
        settingsController.showCreditsFooter = NO;
        settingsController.showDoneButton = NO;
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([notification.object isEqual:@"skip_empty_inventories"]) {
        [self populateInventories];
    }
}

- (void)loadSchemaFinished
{
    [self showInventory];
    [TSMessage dismissActiveNotification];
    [self.view setUserInteractionEnabled:YES];
}

- (void)loadSchemaStarted
{
    [self.view setUserInteractionEnabled:NO];
    [TSMessage showNotificationInViewController:self.navigationController
                                          title:NSLocalizedString(kSCSchemaIsLoading, kSCSchemaIsLoading)
                                       subtitle:NSLocalizedString(kSCSchemaIsLoadingDetail, kSCSchemaIsLoadingDetail)
                                          image:nil
                                           type:TSMessageNotificationTypeMessage
                                       duration:TSMessageNotificationDurationEndless
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                            canBeDismisedByUser:NO];
}

- (void)showInventory
{
    [self performSegueWithIdentifier:@"showInventory" sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCInventory *inventory = [_inventories objectAtIndex:indexPath.row];
    SCInventoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InventoryCell"];
    cell.inventory = inventory;
    [cell loadImage];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _currentInventory = [_inventories objectAtIndex:indexPath.row];
    if (_currentInventory.schema == nil) {
        [_currentInventory loadSchema];
    } else {
        [self showInventory];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_inventories count];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"] == nil) {
        [self performSegueWithIdentifier:@"SteamIDForm" sender:self];
    }
}

- (void)viewDidLoad
{
    self.navigationItem.title = NSLocalizedString(self.navigationItem.title, @"Games");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
