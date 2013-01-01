//
//  SCGamesViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "AFKissXMLRequestOperation.h"
#import "ASIHTTPRequest.h"
#import "DDXMLDocument.h"
#import "DDXMLElement.h"

#import "SCAppDelegate.h"
#import "SCGamesViewController.h"
#import "SCSteamIdFormController.h"

@interface SCGamesViewController () {
    NSArray *_availableGames;
    NSLock *_availableGamesLock;
    NSNumber *_currentAppId;
    NSDictionary *_games;
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
    NSURL *apiListUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/ISteamWebAPIUtil/GetSupportedAPIList/v0001?key=%@", [SCAppDelegate apiKey]]];
    ASIHTTPRequest *apiListRequest = [ASIHTTPRequest requestWithURL:apiListUrl];
    __weak ASIHTTPRequest *weakApiListRequest = apiListRequest;
    [apiListRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [apiListRequest setCompletionBlock:^{
        NSString *errorMsg;

        if ([weakApiListRequest responseStatusCode] >= 500) {
            errorMsg = [weakApiListRequest responseStatusMessage];
        }

        NSError *error = nil;
        NSDictionary *apiListResponse = [[NSJSONSerialization JSONObjectWithData:[weakApiListRequest responseData] options:0 error:&error] objectForKey:@"apilist"];

        if (error != nil) {
            NSLog(@"Error loading available Web API interfaces: %@", errorMsg);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
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
        }
    }];
    [apiListRequest setFailedBlock:^{
        NSError *error = [weakApiListRequest error];
        NSString *errorMessage;
        if (error == nil) {
            errorMessage = [weakApiListRequest responseStatusMessage];
        } else {
            errorMessage = [error localizedDescription];
        }
        NSLog(@"Error loading available Web API interfaces: %@", errorMessage);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading available games" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [_availableGamesLock unlock];
    }];

    [_availableGamesLock lock];
    [apiListRequest startAsynchronous];
}

- (void)loadGames
{
    _games = nil;

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
        NSMutableDictionary *games = [NSMutableDictionary dictionary];

        DDXMLElement *gamesElement = [[[XMLDocument rootElement] elementsForName:@"games"] objectAtIndex:0];
        for (DDXMLElement *gameElement in [gamesElement elementsForName:@"game"]) {
            DDXMLElement *appIdElement = [[gameElement elementsForName:@"appID"] objectAtIndex:0];
            DDXMLElement *nameElement = [[gameElement elementsForName:@"name"] objectAtIndex:0];
            NSNumber *appId = [NSNumber numberWithInt:[[appIdElement stringValue] intValue]];
            [games setObject:[nameElement stringValue] forKey:appId];
        };

        [NSThread detachNewThreadSelector:@selector(populateGames:) toTarget:self withObject:[games copy]];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, DDXMLDocument *XMLDocument) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading user's games: %@", [error localizedDescription]];
        NSLog(@"%@", errorMessage);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
    [gamesRequestOperation start];
    [gamesRequestOperation waitUntilFinished];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)populateGames:(NSDictionary *)games
{
    _games = [NSMutableDictionary dictionary];
    [_availableGamesLock lock];
    [games enumerateKeysAndObjectsUsingBlock:^(NSString *appId, NSString *gameName, BOOL *stop) {
        if ([_availableGames containsObject:appId]) {
            [_games setValue:gameName forKey:appId];
        }
    }];
    [_availableGamesLock unlock];
    _games = [_games copy];

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
        inventoryController.appId = _currentAppId;

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return interfaceOrientation == UIInterfaceOrientationPortrait;
    } else {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GameCell"];
    cell.textLabel.text = [[_games allValues] objectAtIndex:indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _currentAppId = [[_games allKeys] objectAtIndex:indexPath.row];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
