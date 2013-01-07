//
//  SCGamesViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "AFKissXMLRequestOperation.h"
#import "DDXMLDocument.h"
#import "DDXMLElement.h"

#import "SCAppDelegate.h"
#import "SCGame.h"
#import "SCGameCell.h"
#import "SCSteamIdFormController.h"

#import "SCGamesViewController.h"

@interface SCGamesViewController () {
    NSArray *_availableGames;
    NSLock *_availableGamesLock;
    SCGame *_currentGame;
    NSArray *_games;
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
    _games = nil;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];
    });

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [(SCSteamIdFormController *)modal dismissForm:self];
    }

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSURL *gamesUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://steamcommunity.com/profiles/%@/games?xml=1", steamId64]];
#ifdef DEBUG
    NSLog(@"Loading user's games from: %@", gamesUrl);
#endif
    NSURLRequest *gamesRequest = [NSURLRequest requestWithURL:gamesUrl];
    AFKissXMLRequestOperation *gamesRequestOperation = [AFKissXMLRequestOperation XMLDocumentRequestOperationWithRequest:gamesRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, DDXMLDocument *XMLDocument) {
        NSMutableArray *games = [NSMutableArray array];

        DDXMLElement *gamesElement = [[[XMLDocument rootElement] elementsForName:@"games"] objectAtIndex:0];
        for (DDXMLElement *gameElement in [gamesElement elementsForName:@"game"]) {
            [games addObject:[[SCGame alloc] initWithXMLElement:gameElement]];
        };

        [NSThread detachNewThreadSelector:@selector(populateGames:) toTarget:self withObject:[games copy]];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, DDXMLDocument *XMLDocument) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading user's games: %@", [error localizedDescription]];
        [SCAppDelegate errorWithMessage:errorMessage];
    }];
    [gamesRequestOperation start];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)populateGames:(NSArray *)games
{
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

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];

        if ([_games count] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showInventory"]) {
        SCInventoryViewController *inventoryController = segue.destinationViewController;
        inventoryController.game = _currentGame;

        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSchema" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
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
    SCGame *game = [_games objectAtIndex:indexPath.row];
    SCGameCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
    cell.game = game;
    [cell loadImage];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _currentGame = [_games objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"showInventory" sender:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_games count];
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
