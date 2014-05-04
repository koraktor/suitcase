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

#import "SCAbstractInventory.h"
#import "SCAppDelegate.h"
#import "SCCommunityInventory.h"
#import "SCGame.h"
#import "SCInventory.h"
#import "SCWebApiInventory.h"
#import "SCInventoryCell.h"
#import "SCSteamIdFormController.h"

#import "SCGamesViewController.h"

@interface SCGamesViewController () {
    NSArray *_availableGames;
    NSCondition *_availableGamesCondition;
    id <SCInventory> _currentInventory;
    NSArray *_games;
    BOOL _waitingForInventoryReload;
}

@property NSArray *inventories;

@end

@implementation SCGamesViewController

const NSInteger kSCAvailableGamesErrorView = 0;
NSString *const kSCAvailableGamesErrorMessage = @"kSCAvailableGamesErrorMessage";
NSString *const kSCAvailableGamesErrorTitle   = @"kSCAvailableGamesErrorTitle";
const NSInteger kSCGamesErrorView = 1;
NSString *const kSCGamesErrorMessage                = @"kSCGamesErrorMessage";
NSString *const kSCGamesErrorTitle                  = @"kSCGamesErrorTitle";
NSString *const kSCInventoryLoadingFailed           = @"kSCInventoryLoadingFailed";
NSString *const kSCInventoryLoadingFailedDetail     = @"kSCInventoryLoadingFailedDetail";
NSString *const kSCReloadingFailedInventory         = @"kSCReloadingFailedInventory";
NSString *const kSCReloadingFailedInventoryDetail   = @"kSCReloadingFailedInventoryDetail";
NSString *const kSCReloadingOutdatedInventory       = @"kSCReloadingOutdatedInventory";
NSString *const kSCReloadingOutdatedInventoryDetail = @"kSCReloadingOutdatedInventoryDetail";
NSString *const kSCSchemaIsLoading                  = @"kSCSchemaIsLoading";
NSString *const kSCSchemaIsLoadingDetail            = @"kSCSchemaIsLoadingDetail";

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
                                             selector:@selector(inventoryLoaded)
                                                 name:@"inventoryLoaded"
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

    _availableGamesCondition = [[NSCondition alloc] init];
    _waitingForInventoryReload = NO;

    self.navigationItem.title = NSLocalizedString(@"Inventories", @"Inventories");

    FAKIcon *userIcon = [FAKFontAwesome userIconWithSize:0.0];
    self.navigationItem.leftBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [userIcon characterCode]];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                         forState:UIControlStateNormal];

    FAKIcon *wrenchIcon = [FAKFontAwesome wrenchIconWithSize:0.0];
    self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [wrenchIcon characterCode]];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                         forState:UIControlStateNormal];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];
    }

    [super awakeFromNib];
}

- (void)loadAvailableGames
{
    AFHTTPRequestOperation *apiListOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"ISteamWebAPIUtil"
                                                                                           andMethod:@"GetSupportedAPIList"
                                                                                          andVersion:1
                                                                                      withParameters:nil
                                                                                             encoded:NO];
    [apiListOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *apiListResponse = [responseObject objectForKey:@"apilist"];
        NSArray *interfaces = [apiListResponse objectForKey:@"interfaces"];
        NSMutableArray *availableGames = [NSMutableArray array];
        [interfaces enumerateObjectsUsingBlock:^(NSDictionary *interface, NSUInteger idx, BOOL *stop) {
            NSString *interfaceName = [interface valueForKey:@"name"];
            if ([interfaceName hasPrefix:@"IEconItems_"]) {
                NSNumber *appId = [NSNumber numberWithInt:[[interfaceName stringByReplacingCharactersInRange:NSMakeRange(0, 11) withString:@""] intValue]];
                [availableGames addObject:appId];
            }
        }];
        if (![availableGames containsObject:@753]) {
            [availableGames addObject:@753];
        }
        [_availableGamesCondition lock];
        _availableGames = [NSArray arrayWithArray:availableGames];
        [_availableGamesCondition signal];
        [_availableGamesCondition unlock];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    }];
    [apiListOperation start];
}

- (void)loadGames
{
    self.inventories = [NSArray array];
    if (self.tableView != nil) {
        [self.tableView reloadData];
    }

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [modal dismissViewControllerAnimated:YES completion:nil];
    }

    [_availableGamesCondition lock];
    while ([_availableGames count] == 0) {
        [_availableGamesCondition wait];
    }

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSDictionary *params = @{
        @"appids_filter": _availableGames,
        @"steamId": steamId64,
        @"include_appinfo": @1,
        @"include_played_free_games": @1
    };

    [_availableGamesCondition unlock];

    AFHTTPRequestOperation *gamesOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"IPlayerService"
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
        [gameObjects addObject:[SCGame steamGame]];

        [self populateGames:[gameObjects copy]];
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

    [gamesOperation start];
}

- (void)inventoryLoaded
{
    if (_waitingForInventoryReload) {
        [TSMessage dismissActiveNotification];

        _waitingForInventoryReload = NO;

        if ([_currentInventory isSuccessful]) {
            [_currentInventory loadSchema];
        } else {
            [self.view setUserInteractionEnabled:YES];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            [TSMessage showNotificationInViewController:self.navigationController
                                                  title:NSLocalizedString(kSCInventoryLoadingFailed, kSCInventoryLoadingFailed)
                                               subtitle:[NSString stringWithFormat:NSLocalizedString(kSCInventoryLoadingFailedDetail, kSCInventoryLoadingFailedDetail), _currentInventory.game.name]
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSMessageNotificationDurationAutomatic
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                    canBeDismisedByUser:YES];
        }
    }

    [NSThread detachNewThreadSelector:@selector(populateInventories) toTarget:self withObject:nil];
}

- (void)populateInventories
{
#ifdef DEBUG
    NSLog(@"Populating inventories…");
#endif

    __weak SCGamesViewController *weakSelf = self;
    NSBlockOperation *populateOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] valueForKey:@"SteamID64"];

        BOOL skipEmptyInventories;
        NSNumber *rawSkipEmptyInventories = [[NSUserDefaults standardUserDefaults] valueForKey:@"skip_empty_inventories"];
        if (rawSkipEmptyInventories == nil) {
            skipEmptyInventories = YES;
        } else {
            skipEmptyInventories = [rawSkipEmptyInventories boolValue];
        }
        BOOL skipFailedInventories;
        NSNumber *rawSkipFailedInventories = [[NSUserDefaults standardUserDefaults] valueForKey:@"skip_failed_inventories"];
        if (rawSkipFailedInventories == nil) {
            skipFailedInventories = NO;
        } else {
            skipFailedInventories = [rawSkipFailedInventories boolValue];
        }

        _inventories = [NSMutableArray array];
        NSArray *inventories = [[SCAbstractInventory inventoriesForUser:steamId64] allValues];
        [inventories enumerateObjectsUsingBlock:^(id <SCInventory> inventory, NSUInteger idx, BOOL *stop) {
            if (![inventory isSuccessful] && (skipFailedInventories || ![inventory temporaryFailed])) {
                return;
            }
            if (skipEmptyInventories && [inventory isEmpty]) {
                return;
            }
            [(NSMutableArray *)_inventories addObject:inventory];
        }];
        _inventories = [_inventories sortedArrayUsingComparator:^NSComparisonResult(id <SCInventory> inv1, id <SCInventory> inv2) {
            return [inv1.game.name compare:inv2.game.name];
        }];

#ifdef DEBUG
        NSLog(@"Loaded %lu inventories for user %@.", (unsigned long) [weakSelf.inventories count], steamId64);
#endif

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        });
    }];

    [populateOperation start];
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
    NSLog(@"Loaded %lu games for user %@.", (unsigned long) [_games count], steamId64);
#endif

    for (SCGame *game in _games) {
        Class inventoryClass;

        if ([@[@620, @730, @753] containsObject:game.appId]) {
            inventoryClass = [SCCommunityInventory class];
        } else {
            inventoryClass = [SCWebApiInventory class];
        }

        [inventoryClass inventoryForSteamId64:steamId64 andGame:game];
    }

#ifdef DEBUG
    NSLog(@"All games loaded");
#endif
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showInventory"]) {
        SCInventoryViewController *inventoryController = segue.destinationViewController;
        inventoryController.inventory = _currentInventory;
    } else if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        IASKAppSettingsViewController *settingsController = (IASKAppSettingsViewController *)[navigationController.childViewControllers objectAtIndex:0];
        settingsController.title = NSLocalizedString(@"Settings", @"Settings");
        settingsController.showCreditsFooter = NO;
        settingsController.showDoneButton = NO;
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([notification.object isEqual:@"skip_empty_inventories"] ||
        [notification.object isEqual:@"skip_failed_inventories"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self populateInventories];
        });
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
    [TSMessage showNotificationInViewController:self.navigationController
                                          title:NSLocalizedString(kSCSchemaIsLoading, kSCSchemaIsLoading)
                                       subtitle:[NSString stringWithFormat:NSLocalizedString(kSCSchemaIsLoadingDetail, kSCSchemaIsLoadingDetail), _currentInventory.game.name]
                                          image:nil
                                           type:TSMessageNotificationTypeMessage
                                       duration:TSMessageNotificationDurationEndless
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                            canBeDismisedByUser:NO];
}

- (void)prepareInventory
{
    if ([_currentInventory temporaryFailed] || [_currentInventory outdated]) {
        [self.view setUserInteractionEnabled:NO];
        [self reloadInventory];
    } else {
        [_currentInventory loadSchema];
    }
}

- (void)reloadInventory
{
    NSString *messageTitle;
    NSString *messageTitleDetail;
    if ([_currentInventory temporaryFailed]) {
        messageTitle = NSLocalizedString(kSCReloadingFailedInventory, kSCReloadingFailedInventory);
        messageTitleDetail = NSLocalizedString(kSCReloadingFailedInventoryDetail, kSCReloadingFailedInventoryDetail);
    } else {
        messageTitle = NSLocalizedString(kSCReloadingOutdatedInventory, kSCReloadingOutdatedInventory);
        messageTitleDetail = NSLocalizedString(kSCReloadingOutdatedInventoryDetail, kSCReloadingOutdatedInventoryDetail);
    }

    [TSMessage showNotificationInViewController:self.navigationController
                                          title:messageTitle
                                       subtitle:[NSString stringWithFormat:messageTitleDetail, _currentInventory.game.name]
                                          image:nil
                                           type:TSMessageNotificationTypeMessage
                                       duration:TSMessageNotificationDurationEndless
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                            canBeDismisedByUser:NO];

    _waitingForInventoryReload = YES;

    [NSThread detachNewThreadSelector:@selector(reload) toTarget:_currentInventory withObject:nil];
}

- (void)showInventory
{
    [self performSegueWithIdentifier:@"showInventory" sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCInventoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InventoryCell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.inventory = [_inventories objectAtIndex:indexPath.row];
    [cell loadImage];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _currentInventory = [_inventories objectAtIndex:indexPath.row];

    [self prepareInventory];
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

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearItem" object:nil];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
