//
//  SCGamesViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "IASKSettingsReader.h"
#import "IASKAppSettingsViewController.h"
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
    NSSet *_availableGames;
    NSCondition *_availableGamesCondition;
    id <SCInventory> _currentInventory;
    NSArray *_games;
    BOOL _waitingForInventoryReload;
}

@property NSArray *inventories;
@property SCCommunityInventory *steamInventory;

@end

@implementation SCGamesViewController

const NSInteger kSCAvailableGamesErrorView = 0;
NSString *const kSCAvailableGamesErrorMessage = @"kSCAvailableGamesErrorMessage";
NSString *const kSCAvailableGamesErrorTitle   = @"kSCAvailableGamesErrorTitle";
const NSInteger kSCGamesErrorView = 1;
NSString *const kSCGamesErrorMessage                = @"kSCGamesErrorMessage";
NSString *const kSCGamesErrorTitle                  = @"kSCGamesErrorTitle";
NSString *const kSCGamesNoInventories               = @"kSCGamesNoInventories";
NSString *const kSCInventoryLoadingFailed           = @"kSCInventoryLoadingFailed";
NSString *const kSCInventoryLoadingFailedDetail     = @"kSCInventoryLoadingFailedDetail";
NSString *const kSCReloadingFailedInventory         = @"kSCReloadingFailedInventory";
NSString *const kSCReloadingFailedInventoryDetail   = @"kSCReloadingFailedInventoryDetail";
NSString *const kSCReloadingOutdatedInventory       = @"kSCReloadingOutdatedInventory";
NSString *const kSCReloadingOutdatedInventoryDetail = @"kSCReloadingOutdatedInventoryDetail";
NSString *const kSCSchemaIsLoading                  = @"kSCSchemaIsLoading";
NSString *const kSCSchemaIsLoadingDetail            = @"kSCSchemaIsLoadingDetail";

typedef NS_ENUM(NSUInteger, SCInventorySection) {
    SCInventorySectionNoInventories,
    SCInventorySectionSteam,
    SCInventorySectionGames
};

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
}

- (void)clearInventories {
    [self.tableView beginUpdates];

    BOOL noInventories = YES;

    if (self.steamInventory != nil) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationTop];
        noInventories = NO;
    }

    if (self.inventories.count > 0) {
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.inventories.count];
        for (int i = 0; i < self.inventories.count; i ++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:2]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SCInventorySectionGames]
                      withRowAnimation:UITableViewRowAnimationTop];

        noInventories = NO;
    }

    self.inventories = [NSArray array];
    self.steamInventory = nil;

    if (!noInventories) {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationTop];
    }

    [self.tableView endUpdates];
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
        NSMutableSet *availableGames = [NSMutableSet setWithObjects:@753, @104700, nil];
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
        if (![availableGames containsObject:@104700]) {
            [availableGames addObject:@104700];
        }
        if (![availableGames containsObject:@230410]) {
            [availableGames addObject:@230410];
        }
        [_availableGamesCondition lock];
        _availableGames = [NSSet setWithSet:availableGames];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearInventories];
    });

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
        @"appids_filter": _availableGames.allObjects,
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

- (void)inventoryLoaded:(NSNotification *)notification
{
    id <SCInventory> inventory = notification.object;

    NSLog(@"Loaded inventory for game \"%@\"", inventory.game.name);

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

    if (_waitingForInventoryReload) {
        [TSMessage dismissActiveNotificationWithCompletion:^{
            _waitingForInventoryReload = NO;

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

        NSIndexPath *indexPath;
        if ([inventory.game isSteam]) {
            indexPath = [NSIndexPath indexPathForRow:0 inSection:SCInventorySectionSteam];
        } else {
            indexPath = [NSIndexPath indexPathForRow:[self.inventories indexOfObject:inventory] inSection:SCInventorySectionGames];
        }

        [self.tableView beginUpdates];
        if (skipped) {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
        [self.tableView endUpdates];
    } else {
        if (skipped) {
            return;
        }

        [self.tableView beginUpdates];
        if (self.steamInventory == nil && self.inventories.count == 0) {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionNoInventories]]
                                  withRowAnimation:UITableViewRowAnimationTop];
        }

        if ([inventory.game isSteam]) {
            self.steamInventory = inventory;
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SCInventorySectionSteam]]
                                                    withRowAnimation:UITableViewRowAnimationTop];
        } else {
            NSMutableArray *otherInventories = [NSMutableArray arrayWithCapacity:self.inventories.count];
            [self.inventories enumerateObjectsUsingBlock:^(id <SCInventory> otherInventory, NSUInteger row, BOOL *stop) {
                [otherInventories addObject:[NSIndexPath indexPathForRow:row inSection:SCInventorySectionGames]];
            }];

            NSArray *newInventories = [self.inventories arrayByAddingObject:inventory];
            self.inventories = [newInventories sortedArrayUsingComparator:^NSComparisonResult(id <SCInventory> inv1, id <SCInventory> inv2) {
                return [inv1.game.name compare:inv2.game.name];
            }];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.inventories indexOfObject:inventory] inSection:SCInventorySectionGames]]
                                  withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView reloadRowsAtIndexPaths:otherInventories withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView endUpdates];

#ifdef DEBUG
        NSUInteger inventoryCount = self.inventories.count;
        if (_steamInventory != nil) {
            inventoryCount ++;
        }
        NSLog(@"Loaded %lu inventories.", (unsigned long) inventoryCount);
#endif
    }
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

        if ([@[@620, @730, @753, @104700, @230410, @238460] containsObject:game.appId]) {
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
    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] valueForKey:@"SteamID64"];
    NSArray *inventories = [[SCAbstractInventory inventoriesForUser:steamId64] allValues];
    NSMutableArray *newInventories = [NSMutableArray arrayWithCapacity:inventories.count];

    BOOL skipEmptyInventories = [[[NSUserDefaults standardUserDefaults] valueForKey:@"skip_empty_inventories"] boolValue];
    BOOL skipFailedInventories = [[[NSUserDefaults standardUserDefaults] valueForKey:@"skip_failed_inventories"] boolValue];

    self.steamInventory = nil;

    [inventories enumerateObjectsUsingBlock:^(id <SCInventory> inventory, NSUInteger idx, BOOL *stop) {
        if (![inventory isLoaded] || [inventory failed]) {
            return;
        }

        if ([inventory isSuccessful] && skipEmptyInventories && [inventory isEmpty]) {
            return;
        } else if (skipFailedInventories && [inventory temporaryFailed]) {
            return;
        }

        if ([inventory.game isSteam]) {
            self.steamInventory = inventory;
        } else {
            [newInventories addObject:inventory];
        }
    }];

    self.inventories = [newInventories sortedArrayUsingComparator:^NSComparisonResult(id <SCInventory> inv1, id <SCInventory> inv2) {
        return [inv1.game.name compare:inv2.game.name];
    }];

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    } else {
        [self.tableView reloadData];
    }
}

- (void)loadSchemaFinished
{
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

    _waitingForInventoryReload = YES;

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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != SCInventorySectionGames || [self.inventories count] == 0) {
        return nil;
    }

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 20.0)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];

    headerLabel.backgroundColor = UIColor.clearColor;
    headerLabel.text = NSLocalizedString(@"Games", @"Games");
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = UIColor.whiteColor;

    UIColor *backgroundColor = [UIColor colorWithRed:0.5372 green:0.6196 blue:0.7294 alpha:1.0];
    CGFloat fontSize = 16.0;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        headerView.alpha = 0.8f;
        headerLabel.font = [UIFont boldSystemFontOfSize:fontSize];

        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = headerView.bounds;
        gradient.colors = @[ (id)[backgroundColor CGColor], (id)[[UIColor colorWithRed:0.2118 green:0.2392 blue:0.2706 alpha:1.0] CGColor] ];
        [headerView.layer addSublayer:gradient];

        headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
        headerView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        headerView.layer.shadowOpacity = 0.5f;
        headerView.layer.shadowRadius = 3.25f;
        headerView.layer.masksToBounds = NO;
    } else {
        headerView.alpha = 1.0f;
        headerLabel.font = [UIFont systemFontOfSize:fontSize];
        headerView.backgroundColor = backgroundColor;
    }

    [headerView addSubview:headerLabel];

    return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
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

    [self prepareInventory];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
