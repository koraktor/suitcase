//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "SCInventoryViewController.h"

#import "ASIHTTPRequest.h"
#import "IASKSettingsReader.h"
#import "SCAppDelegate.h"
#import "SCInventory.h"
#import "SCItemViewController.h"
#import "SCItem.h"
#import "SCItemCell.h"
#import "SCSchema.h"
#import "SCSettingsViewController.h"
#import "SCSteamIdFormController.h"
#import "UIImageView+ASIHTTPRequest.h"

@interface SCInventoryViewController () {
    SCInventory *_inventory;
	SCSchema *_itemSchema;
    NSLock *_schemaLock;
}
@end

@implementation SCInventoryViewController

@synthesize detailViewController = _detailViewController;
@synthesize game = _game;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadSchema)
                                                 name:@"loadSchema" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadInventory)
                                                 name:@"loadInventory"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshInventory)
                                                 name:@"refreshInventory"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sortInventory)
                                                 name:@"sortInventory"
                                               object:nil];

    _schemaLock = [[NSLock alloc] init];

    [super awakeFromNib];
}

- (void)loadInventory
{
    SCInventory *inventory = [SCInventory currentInventory];
    if (inventory != nil && inventory.game == _game) {
        _inventory = inventory;
        [self.tableView setDataSource:_inventory];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.tableView reloadData];

            if ([_inventory.itemSections count] > 0 && [[_inventory.itemSections objectAtIndex:0] count] > 0) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        });

        return;
    }

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [(SCSteamIdFormController *)modal dismissForm:self];
    }

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSURL *inventoryUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_%@/GetPlayerItems/v0001?steamid=%@&key=%@", _game.appId, steamId64, [SCAppDelegate apiKey]]];
#ifdef DEBUG
    NSLog(@"Loading inventory contents from: %@", inventoryUrl);
#endif
    ASIHTTPRequest *inventoryRequest = [ASIHTTPRequest requestWithURL:inventoryUrl];
    __weak ASIHTTPRequest *weakInventoryRequest = inventoryRequest;
    [inventoryRequest setCompletionBlock:^{
        NSString *errorMsg;

        if ([weakInventoryRequest responseStatusCode] >= 500) {
            errorMsg = [weakInventoryRequest responseStatusMessage];
        }

        NSError *error = nil;
        NSDictionary *inventoryResponse = [[NSJSONSerialization JSONObjectWithData:[weakInventoryRequest responseData] options:0 error:&error] objectForKey:@"result"];

        if (error != nil) {
            errorMsg = [error localizedDescription];
        }

        if (![[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [inventoryResponse objectForKey:@"statusDetail"]];
        }

        if (errorMsg == nil) {
            NSArray *itemsResponse = [inventoryResponse objectForKey:@"items"];
            [NSThread detachNewThreadSelector:@selector(populateInventoryWithData:) toTarget:self withObject:itemsResponse];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
    [inventoryRequest setFailedBlock:^{
        NSError *error = [weakInventoryRequest error];
        NSString *errorMessage;
        if (error == nil) {
            errorMessage = [weakInventoryRequest responseStatusMessage];
        } else {
            errorMessage = [error localizedDescription];
        }
        NSLog(@"Error loading inventory contents: %@", errorMessage);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading the inventory contents" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [inventoryRequest startAsynchronous];
}

- (void)loadSchema {
    SCInventory *inventory = [SCInventory currentInventory];
    if (inventory != nil && inventory.game == _game) {
        return;
    }

    NSURL *schemaUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_%@/GetSchema/v0001?key=%@&language=%@", _game.appId, [SCAppDelegate apiKey], [[NSLocale preferredLanguages] objectAtIndex:0]]];
#ifdef DEBUG
    NSLog(@"Loading item schema data from: %@", schemaUrl);
#endif
    ASIHTTPRequest *schemaRequest = [ASIHTTPRequest requestWithURL:schemaUrl];
    __weak ASIHTTPRequest *weakSchemaRequest = schemaRequest;
    [schemaRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [schemaRequest setCompletionBlock:^{
        NSString *errorMsg;

        if ([weakSchemaRequest responseStatusCode] >= 500) {
            errorMsg = [weakSchemaRequest responseStatusMessage];
        }

        NSError *error = nil;
        NSDictionary *schemaResponse = [[NSJSONSerialization JSONObjectWithData:[weakSchemaRequest responseData] options:0 error:&error] objectForKey:@"result"];

        if (error != nil) {
            errorMsg = [error localizedDescription];
        }

        if (![[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            errorMsg = [NSString stringWithFormat:@"Error loading the item schema: %@", [schemaResponse objectForKey:@"statusDetail"]];
        }

        if (errorMsg == nil) {
            _itemSchema = [[SCSchema alloc] initWithDictionary:schemaResponse];
        } else {
            NSLog(@"Error loading game item schema: %@", errorMsg);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }

        [_schemaLock unlock];
    }];
    [schemaRequest setFailedBlock:^{
        NSError *error = [weakSchemaRequest error];
        NSString *errorMessage;
        if (error == nil) {
            errorMessage = [weakSchemaRequest responseStatusMessage];
        } else {
            errorMessage = [error localizedDescription];
        }
        NSLog(@"Error loading game item schema: %@", errorMessage);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading game item schema" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [_schemaLock unlock];
    }];
    [schemaRequest setTimeOutSeconds:60.0];

    _itemSchema = nil;
    [_schemaLock lock];
    [schemaRequest startAsynchronous];
}

- (void)populateInventoryWithData:(NSArray *)itemsData {
    self.detailViewController.detailItem = nil;

    [_schemaLock lock];
    _inventory = [[SCInventory alloc] initWithItems:itemsData andGame:_game andSchema:_itemSchema];
    [_schemaLock unlock];
    [_inventory sortItems];
    [self.tableView setDataSource:_inventory];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];

        if ([_inventory.itemSections count] > 0 && [[_inventory.itemSections objectAtIndex:0] count] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    });
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([[notification object] isEqual:@"sorting"]) {
        [self sortInventory];
    } else if ([[notification object] isEqual:@"show_colors"]) {
        _inventory.showColors = [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"] boolValue];
        [self refreshInventory];
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.detailViewController = (SCItemViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.navigationItem.title = NSLocalizedString(self.navigationItem.title, @"Inventory title");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return interfaceOrientation == UIInterfaceOrientationPortrait;
    } else {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    }
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        SCItem *item = [[_inventory.itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        self.detailViewController.detailItem = item;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        SCItem *item = [[_inventory.itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [segue.destinationViewController setDetailItem:item];
    } else if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        SCSettingsViewController *settingsController = (SCSettingsViewController *)[navigationController.childViewControllers objectAtIndex:0];
        settingsController.title = NSLocalizedString(@"Settings", @"Settings");
        settingsController.delegate = self;
        settingsController.showCreditsFooter = NO;
        settingsController.showDoneButton = NO;
    }
}

- (void)refreshInventory
{
    for (SCItemCell *cell in [self.tableView visibleCells]) {
        cell.showColors = _inventory.showColors;
        [cell changeColor];
    }
}

- (void)sortInventory
{
    [_inventory sortItems];
    [self.tableView reloadData];

    if ([_inventory.itemSections count] > 0 && [[_inventory.itemSections objectAtIndex:0] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
