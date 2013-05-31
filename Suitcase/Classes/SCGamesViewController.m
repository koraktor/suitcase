//
//  SCGamesViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FontAwesomeKit.h"

#import "SCAppDelegate.h"
#import "SCGame.h"
#import "SCGameCell.h"
#import "SCInventory.h"
#import "SCSteamIdFormController.h"

#import "SCGamesViewController.h"

@interface SCGamesViewController () {
    NSArray *_availableGames;
    NSLock *_availableGamesLock;
    SCInventory *_currentInventory;
    NSArray *_games;
    NSLock *_gamesLock;
    NSArray *_inventories;
}
@end

@implementation SCGamesViewController

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadAvailableGames)
                                                 name:@"loadAvailableGames"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadGames)
                                                 name:@"loadGames"
                                               object:nil];

    _availableGamesLock = [[NSLock alloc] init];
    _gamesLock = [[NSLock alloc] init];

    self.navigationItem.leftBarButtonItem.title = FAKIconUser;
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FontAwesomeKit fontWithSize:20]}
                                                         forState:UIControlStateNormal];
    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];

    self.navigationItem.rightBarButtonItem.title = FAKIconWrench;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FontAwesomeKit fontWithSize:20]}
                                                         forState:UIControlStateNormal];
    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];

    [super awakeFromNib];
}

- (void)loadAvailableGames
{
    AFJSONRequestOperation *apiListOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"ISteamWebAPIUtil"
                                                                                           andMethod:@"GetSupportedAPIList"
                                                                                          andVersion:1
                                                                                      withParameters:nil];
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
        NSString *errorMessage = [error description];
#ifdef DEBUG
        NSLog(@"%@", errorMessage);
#endif
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:errorMessage
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }];
    [_availableGamesLock lock];
    [apiListOperation start];
}

- (void)loadGames
{
    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [(SCSteamIdFormController *)modal dismissForm:self];
    }

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSDictionary *params = @{@"steamId": steamId64, @"include_appinfo": @1, @"include_played_free_games": @1};
    AFJSONRequestOperation *gamesOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"IPlayerService"
                                                                                          andMethod:@"GetOwnedGames"
                                                                                         andVersion:1
                                                                                     withParameters:params];
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
        NSString *errorMessage = [error description];
#ifdef DEBUG
        NSLog(@"%@", errorMessage);
#endif
        [SCAppDelegate errorWithMessage:errorMessage];
    }];
    [_gamesLock lock];
    [gamesOperation start];
}

- (void)populateInventories
{
    NSString *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];

    _inventories = [NSMutableArray array];
    NSArray *inventories = [[[SCInventory inventories] valueForKeyPath:steamId64] allValues];
    [inventories enumerateObjectsUsingBlock:^(SCInventory *inventory, NSUInteger idx, BOOL *stop) {
        if (![inventory isEmpty] && [inventory isSuccessful]) {
            [(NSMutableArray *)_inventories addObject:inventory];
        }
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
    [_gamesLock lock];

    _games = [NSMutableArray array];
    [_availableGamesLock lock];
    [games enumerateObjectsUsingBlock:^(SCGame *game, NSUInteger idx, BOOL *stop) {
        if ([_availableGames containsObject:game.appId]) {
            [(NSMutableArray *)_games addObject:game];
        }
    }];
    [_availableGamesLock unlock];
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

    [_gamesLock unlock];

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
        if (inventoryController.inventory == _currentInventory) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadInventory" object:nil];
        } else {
            inventoryController.inventory = _currentInventory;
        }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCInventory *inventory = [_inventories objectAtIndex:indexPath.row];
    SCGameCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
    cell.game = inventory.game;
    [cell loadImage];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _currentInventory = [_inventories objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"showInventory" sender:self];
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
