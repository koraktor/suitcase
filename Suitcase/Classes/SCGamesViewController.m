//
//  SCGamesViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import "FAKFontAwesome.h"
#import "IASKSettingsReader.h"
#import "IASKAppSettingsViewController.h"
#import "TSMessage.h"

#import "SCAbstractInventory.h"
#import "SCAppDelegate.h"
#import "SCCommunityInventory.h"
#import "SCGame.h"
#import "SCHeaderView.h"
#import "SCInventory.h"
#import "SCWebApiInventory.h"
#import "SCInventoryCell.h"
#import "SCSteamIdFormController.h"

#import "SCGamesViewController.h"

@interface SCGamesViewController () {
    id <SCInventory> _currentInventory;
    NSArray *_games;
    NSInteger _reloadingInventoriesCount;
}

@property NSArray *inventories;
@property SCCommunityInventory *steamInventory;

@end

@implementation SCGamesViewController

NSString *const kSCGamesErrorMessage                = @"kSCGamesErrorMessage";
NSString *const kSCGamesErrorTitle                  = @"kSCGamesErrorTitle";
NSString *const kSCGamesNoInventories               = @"kSCGamesNoInventories";
NSString *const kSCInventoryLoadingFailed           = @"kSCInventoryLoadingFailed";
NSString *const kSCInventoryLoadingFailedDetail     = @"kSCInventoryLoadingFailedDetail";
NSString *const kSCReloadingFailedInventory         = @"kSCReloadingFailedInventory";
NSString *const kSCReloadingFailedInventoryDetail   = @"kSCReloadingFailedInventoryDetail";
NSString *const kSCReloadingOutdatedInventory       = @"kSCReloadingOutdatedInventory";
NSString *const kSCReloadingOutdatedInventoryDetail = @"kSCReloadingOutdatedInventoryDetail";
NSString *const kSCSchemaFailed                     = @"kSCSchemaFailed";
NSString *const kSCSchemaIsLoading                  = @"kSCSchemaIsLoading";
NSString *const kSCSchemaIsLoadingDetail            = @"kSCSchemaIsLoadingDetail";

typedef NS_ENUM(NSUInteger, SCInventorySection) {
    SCInventorySectionNoInventories,
    SCInventorySectionSteam,
    SCInventorySectionGames
};

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self loadGames];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SteamID64"];
        [self performSegueWithIdentifier:@"SteamIDForm" sender:self];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inventoryLoaded:)
                                                 name:@"inventoryLoaded"
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
                                             selector:@selector(loadSchemaFinished:)
                                                 name:@"loadSchemaFinished"
                                               object:nil];

    _reloadingInventoriesCount = 0;

    FAKIcon *userIcon = [FAKFontAwesome userIconWithSize:0.0];
    self.navigationItem.leftBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [userIcon characterCode]];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                         forState:UIControlStateNormal];
}

- (void)clearInventories {
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }

    [self.tableView beginUpdates];

    BOOL noInventories = YES;

    if (self.steamInventory != nil) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationTop];
        noInventories = NO;
    }

    if (self.inventories.count > 0) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:SCInventorySectionGames]
                      withRowAnimation:UITableViewRowAnimationTop];
        noInventories = NO;
    }

    self.inventories = [NSArray array];
    self.steamInventory = nil;

    if (!noInventories) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionNoInventories]]
                              withRowAnimation:UITableViewRowAnimationTop];
    }

    [self.tableView endUpdates];
}

- (void)loadGames
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearInventories];
    });

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [modal dismissViewControllerAnimated:YES completion:nil];
    }

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSDictionary *params = @{
        @"appids_filter": [[SCGame communityInventories] arrayByAddingObjectsFromArray:[SCGame webApiInventories]],
        @"steamId": steamId64,
        @"include_appinfo": @1,
        @"include_played_free_games": @1
    };

    AFHTTPRequestOperation *gamesOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"IPlayerService"
                                                                                         andMethod:@"GetOwnedGames"
                                                                                        andVersion:1
                                                                                    withParameters:params
                                                                                           encoded:YES
                                                                                     modifiedSince:nil];
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
        [alertView show];
    }];

    [gamesOperation start];
}

- (void)inventoryLoaded:(NSNotification *)notification
{
    id <SCInventory> inventory = notification.object;

#ifdef DEBUG
    NSLog(@"Loaded inventory for game \"%@\" (App ID %@)", inventory.game.name, inventory.game.appId);
#endif

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    if (![inventory.steamId64 isEqual:steamId64]) {
#ifdef DEBUG
        NSLog(@"Discarding inventory for different user.");
#endif
        return;
    }

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

    BOOL skipped = NO;
    if ([inventory failed]) {
        skipped = YES;
    } else if ([inventory isSuccessful] && skipEmptyInventories && [inventory isEmpty]) {
        skipped = YES;
    } else if (skipFailedInventories && [inventory temporaryFailed]) {
        skipped = YES;
    }

    BOOL refreshing = _reloadingInventoriesCount > 0;
    if (refreshing) {
        if ([TSMessage isNotificationActive]) {
            [TSMessage dismissActiveNotificationWithCompletion:^{
                _reloadingInventoriesCount --;

                if ([_currentInventory isSuccessful]) {
                    [_currentInventory loadSchema];
                } else {
                    [self.view setUserInteractionEnabled:YES];
                    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

                    [SCAppDelegate errorWithTitle:NSLocalizedString(kSCInventoryLoadingFailed, kSCInventoryLoadingFailed)
                                       andMessage:[NSString stringWithFormat:NSLocalizedString(kSCInventoryLoadingFailedDetail, kSCInventoryLoadingFailedDetail), _currentInventory.game.name]
                                     inController:self];
                }
            }];
        } else {
            _reloadingInventoriesCount --;
        }
    } else if (skipped) {
        return;
    }

    void (^refreshCompletion)(BOOL) = nil;
    if (refreshing) {
        refreshCompletion = ^void (BOOL finished) {
            if (_reloadingInventoriesCount == 0) {
                [self setRefreshControlTitle:NSLocalizedString(@"Refresh", @"Refresh")];

                [self.refreshControl endRefreshing];
            }
        };
    }

    BOOL gamesBefore = self.inventories.count != 0;
    NSUInteger inventoryCount = self.inventories.count + ((self.steamInventory == nil) ? 0 : 1);
    BOOL inventoriesBefore = inventoryCount != 0;
    NSIndexPath *indexPath;
    BOOL visibleBefore;
    if ([inventory.game isSteam]) {
        visibleBefore = self.steamInventory != nil;
        self.steamInventory = skipped ? nil : inventory;
        indexPath = [NSIndexPath indexPathForRow:0 inSection:SCInventorySectionSteam];
    } else {
        visibleBefore = [self.inventories containsObject:inventory];

        NSMutableArray *newInventories = [self.inventories mutableCopy];
        if (skipped && visibleBefore) {
            indexPath = [NSIndexPath indexPathForRow:[self.inventories indexOfObject:inventory]
                                           inSection:SCInventorySectionGames];
            [newInventories removeObject:inventory];
            self.inventories = [newInventories copy];
        } else if (!visibleBefore && !skipped) {
            [newInventories addObject:inventory];
            self.inventories = [newInventories sortedArrayUsingSelector:@selector(compare:)];
        }

        if (indexPath == nil) {
            indexPath = [NSIndexPath indexPathForRow:[self.inventories indexOfObject:inventory]
                                           inSection:SCInventorySectionGames];
        }
    }
    BOOL gamesAfter = self.inventories.count != 0;
    inventoryCount = self.inventories.count + ((self.steamInventory == nil) ? 0 : 1);
    BOOL inventoriesAfter = inventoryCount != 0;

    [UIView transitionWithView:self.tableView
                      duration:0.2
                       options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveLinear
                    animations:^{
        [self.tableView beginUpdates];

        if (skipped) {
            if (visibleBefore) {
                if (!inventoriesAfter) {
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionNoInventories]]
                                          withRowAnimation:UITableViewRowAnimationTop];
                }
                if (!inventory.game.isSteam && gamesBefore && !gamesAfter) {
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:SCInventorySectionGames]
                                  withRowAnimation:UITableViewRowAnimationFade];
                } else {
                    [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                          withRowAnimation:UITableViewRowAnimationFade];
                }
            }
        } else {
            if (!visibleBefore) {
                if (!inventoriesBefore) {
                    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionNoInventories]]
                                          withRowAnimation:UITableViewRowAnimationFade];
                }
                if (!inventory.game.isSteam && !gamesBefore) {
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:SCInventorySectionGames]
                                  withRowAnimation:UITableViewRowAnimationTop];
                }
                [self.tableView insertRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationTop];
            } else {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
        }

        [self.tableView endUpdates];


        if (refreshing && _reloadingInventoriesCount > 0) {
            self.tableView.contentOffset = CGPointMake(0.0, -self.tableView.contentInset.top);
        }
    } completion:refreshCompletion];

#ifdef DEBUG
    NSLog(@"Loaded %lu inventories.", (unsigned long)inventoryCount);
#endif
}

- (void)populateGames:(NSArray *)games
{
    NSArray *availableGames = [[SCGame communityInventories] arrayByAddingObjectsFromArray:[SCGame webApiInventories]];

    _games = [NSMutableArray array];
    for (SCGame *game in games) {
        if ([availableGames containsObject:game.appId]) {
            [(NSMutableArray *)_games addObject:game];
        }
    };
    _games = [_games copy];

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];

#ifdef DEBUG
    NSLog(@"Loaded %lu games for user %@.", (unsigned long) [_games count], steamId64);
#endif

    for (SCGame *game in _games) {
        Class inventoryClass;

        if ([[SCGame webApiInventories] containsObject:game.appId]) {
            inventoryClass = [SCWebApiInventory class];
        } else {
            inventoryClass = [SCCommunityInventory class];
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
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        SCInventoryViewController *inventoryController = segue.destinationViewController;
        inventoryController.inventory = _currentInventory;
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)settingsChanged:(NSNotification *)notification {
    if (![notification.userInfo.allKeys containsObject:@"skip_empty_inventories"] &&
        ![notification.userInfo.allKeys containsObject:@"skip_failed_inventories"]) {
        return;
    }

    BOOL skipEmptyInventories = [[[NSUserDefaults standardUserDefaults] valueForKey:@"skip_empty_inventories"] boolValue];
    BOOL skipFailedInventories = [[[NSUserDefaults standardUserDefaults] valueForKey:@"skip_failed_inventories"] boolValue];

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] valueForKey:@"SteamID64"];
    NSArray *inventories = [[SCAbstractInventory inventoriesForUser:steamId64] allValues];
    NSMutableArray *newInventories = [NSMutableArray arrayWithCapacity:inventories.count];
    __block SCCommunityInventory *newSteamInventory = nil;

    for (id<SCInventory> inventory in inventories) {
        if (![inventory isLoaded] || [inventory failed]) {
            return;
        }

        if ([inventory isSuccessful] && skipEmptyInventories && [inventory isEmpty]) {
            return;
        } else if (skipFailedInventories && [inventory temporaryFailed]) {
            return;
        }

        if ([inventory.game isSteam]) {
            newSteamInventory = inventory;
        } else {
            [newInventories addObject:inventory];
        }
    };

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.tableView beginUpdates];

        BOOL steamInventoryEmptyBefore = self.steamInventory == nil;
        self.steamInventory = newSteamInventory;
        BOOL steamInventoryEmptyAfter = self.steamInventory == nil;
        if (steamInventoryEmptyBefore != steamInventoryEmptyAfter) {
            NSArray *steamIndexPath = @[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionSteam]];
            if (steamInventoryEmptyBefore) {
                [self.tableView insertRowsAtIndexPaths:steamIndexPath withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView deleteRowsAtIndexPaths:steamIndexPath withRowAnimation:UITableViewRowAnimationFade];
            }
        }

        NSUInteger inventoryCountBefore = [self.inventories count];
        self.inventories = [newInventories sortedArrayUsingSelector:@selector(compare:)];
        NSUInteger inventoryCountAfter = [self.inventories count];
        NSIndexSet *gamesSection = [NSIndexSet indexSetWithIndex:SCInventorySectionGames];
        if (inventoryCountBefore != inventoryCountAfter) {
            if (inventoryCountBefore == 0) {
                [self.tableView insertSections:gamesSection withRowAnimation:UITableViewRowAnimationFade];
            } else if (inventoryCountAfter == 0) {
                [self.tableView deleteSections:gamesSection withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView reloadSections:gamesSection withRowAnimation:UITableViewRowAnimationFade];
            }
        }

        NSArray *noInventoriesPath = @[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionNoInventories]];
        if (steamInventoryEmptyBefore && inventoryCountBefore == 0 && !(steamInventoryEmptyAfter && inventoryCountAfter == 0)) {
            [self.tableView deleteRowsAtIndexPaths:noInventoriesPath withRowAnimation:UITableViewRowAnimationFade];
        } else if (!(steamInventoryEmptyBefore && inventoryCountBefore == 0) && steamInventoryEmptyAfter && inventoryCountAfter == 0) {
            [self.tableView insertRowsAtIndexPaths:noInventoriesPath withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView endUpdates];
    } else {
        self.inventories = [newInventories sortedArrayUsingSelector:@selector(compare:)];
        [self.tableView reloadData];
    }
}

- (void)loadSchemaFinished:(NSNotification *)notification
{
    if ([_currentInventory isMemberOfClass:[SCWebApiInventory class]] && ((SCWebApiInventory *)_currentInventory).schema == nil) {
        if ([TSMessage isNotificationActive]) {
            [TSMessage dismissActiveNotification];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (notification.object != nil) {
                [SCAppDelegate errorWithTitle:NSLocalizedString(kSCSchemaFailed, kSCSchemaFailed)
                                   andMessage:(NSString *)notification.object
                                 inController:self];
            }

            [self.view setUserInteractionEnabled:YES];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        });

        return;
    }

    void (^showInventory)() = ^() {
        [self showInventory];
        [self.view setUserInteractionEnabled:YES];

    };

    if (![TSMessage isNotificationActive]) {
        showInventory();
    } else {
        [TSMessage dismissActiveNotificationWithCompletion:showInventory];
    }
}

- (void)loadSchemaStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:NSLocalizedString(kSCSchemaIsLoading, kSCSchemaIsLoading)
                                           subtitle:[NSString stringWithFormat:NSLocalizedString(kSCSchemaIsLoadingDetail, kSCSchemaIsLoadingDetail), _currentInventory.game.name]
                                               type:TSMessageNotificationTypeMessage
                                           duration:TSMessageNotificationDurationEndless
                               canBeDismissedByUser:NO];
    });
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
                                           type:TSMessageNotificationTypeMessage
                                       duration:TSMessageNotificationDurationEndless
                           canBeDismissedByUser:NO];

    _reloadingInventoriesCount ++;

    [NSThread detachNewThreadSelector:@selector(reload) toTarget:_currentInventory withObject:nil];
}

- (void)showInventory
{
    [self performSegueWithIdentifier:@"showInventory" sender:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section != SCInventorySectionGames || [self.inventories count] == 0) {
        return 0.0;
    }

    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != SCInventorySectionGames) {
        return nil;
    }

    SCHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"SCHeaderView"];
    headerView.textLabel.text = NSLocalizedString(@"Games", @"Games");

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        if (headerView.backgroundView == nil) {
            headerView.backgroundView = [[UIView alloc] initWithFrame:headerView.frame];
        }
        [self tableView:tableView willDisplayHeaderView:headerView forSection:section];
    }

    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    SCHeaderView *headerView = (SCHeaderView *)view;
    headerView.textLabel.adjustsFontSizeToFitWidth = YES;
    headerView.textLabel.textAlignment = NSTextAlignmentCenter;
    headerView.textLabel.center = headerView.center;

    headerView.backgroundColor = SCHeaderView.defaultBackgroundColor;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.inventories.count == 0) {
        return SCInventorySectionGames;
    }

    return SCInventorySectionGames + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SCInventorySectionNoInventories) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoInventoriesCell"];
        cell.textLabel.text = NSLocalizedString(kSCGamesNoInventories, kSCGamesNoInventories);
        return cell;
    }

    SCInventoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InventoryCell"];
    if (indexPath.section == SCInventorySectionSteam) {
        cell.inventory = self.steamInventory;
    } else {
        cell.inventory = [self.inventories objectAtIndex:indexPath.row];
    }
    [cell loadImage];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SCInventorySectionNoInventories) {
        return;
    }

    if (indexPath.section == SCInventorySectionSteam) {
        _currentInventory = self.steamInventory;
    } else {
        _currentInventory = [self.inventories objectAtIndex:indexPath.row];
    }
    SCAbstractInventory.currentInventory = _currentInventory;

    if (_currentInventory.isRetrying) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [self prepareInventory];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SCInventorySectionNoInventories) {
        return (self.steamInventory == nil && self.inventories.count == 0) ? 1 : 0;
    } else if (section == SCInventorySectionSteam) {
        return (self.steamInventory == nil) ? 0 : 1;
    } else {
        return [self.inventories count];
    }
}

#pragma mark - Refresh Control

- (IBAction)triggerRefresh:(id)sender {
    [super triggerRefresh:sender];

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    [[SCAbstractInventory inventoriesForUser:steamId64] enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id<SCInventory> _Nonnull inventory, BOOL *_Nonnull stop) {
        if (![inventory failed]) {
            _reloadingInventoriesCount ++;
            [NSThread detachNewThreadSelector:@selector(reload) toTarget:inventory withObject:nil];
        }
    }];

    if (_reloadingInventoriesCount == 0) {
        [self setRefreshControlTitle:NSLocalizedString(@"Refresh", @"Refresh")];

        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Language Support

- (void)reloadStrings {
    [super reloadStrings];

    self.navigationItem.title = NSLocalizedString(@"Inventories", @"Inventories");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"] == nil) {
        [self performSegueWithIdentifier:@"SteamIDForm" sender:self];
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearItem" object:nil];
    }
}

@end
