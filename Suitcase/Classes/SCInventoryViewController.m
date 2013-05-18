//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "FontAwesomeKit.h"
#import "IASKSettingsReader.h"

#import "SCAppDelegate.h"
#import "SCInventory.h"
#import "SCItemViewController.h"
#import "SCItem.h"
#import "SCItemCell.h"
#import "SCSchema.h"
#import "SCSettingsViewController.h"
#import "SCSteamIdFormController.h"

#import "SCInventoryViewController.h"

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

    self.navigationItem.rightBarButtonItem.title = FAKIconWrench;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FontAwesomeKit fontWithSize:20]}
                                                          forState:UIControlStateNormal];

    [super awakeFromNib];
}

- (void)loadInventory
{
    SCInventory *inventory = [SCInventory currentInventory];
    if (inventory != nil && inventory.game == _game) {
        _inventory = inventory;
        [self reloadInventory];

        return;
    }

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [(SCSteamIdFormController *)modal dismissForm:self];
    }

    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSDictionary *params = [NSDictionary dictionaryWithObject:steamId64 forKey:@"steamid"];
    AFJSONRequestOperation *inventoryOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:[NSString stringWithFormat:@"IEconItems_%@", _game.appId]
                                                                                             andMethod:@"GetPlayerItems"
                                                                                            andVersion:1
                                                                                        withParameters:params];
    [inventoryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *inventoryResponse = [responseObject objectForKey:@"result"];

        if ([[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSArray *itemsResponse = [inventoryResponse objectForKey:@"items"];
            [NSThread detachNewThreadSelector:@selector(populateInventoryWithData:) toTarget:self withObject:itemsResponse];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"Error loading the inventory: %@", [inventoryResponse objectForKey:@"statusDetail"]];
            [SCAppDelegate errorWithMessage:errorMessage];

        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading the inventory: %@", [error localizedDescription]];
        [SCAppDelegate errorWithMessage:errorMessage];

    }];
    [inventoryOperation start];
}

- (void)loadSchema {
    SCInventory *inventory = [SCInventory currentInventory];
    if (inventory != nil && inventory.game == _game) {
        return;
    }

    NSDictionary *params = [NSDictionary dictionaryWithObject:[[NSLocale preferredLanguages] objectAtIndex:0] forKey:@"language"];
    AFJSONRequestOperation *schemaOperation = [[SCAppDelegate webApiClient] jsonRequestForInterface:[NSString stringWithFormat:@"IEconItems_%@", _game.appId]
                                                                                          andMethod:@"GetSchema"
                                                                                         andVersion:1
                                                                                     withParameters:params];
    [schemaOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *schemaResponse = [responseObject objectForKey:@"result"];

        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            _itemSchema = [[SCSchema alloc] initWithDictionary:schemaResponse];
            [_schemaLock unlock];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"Error loading the inventory: %@", [schemaResponse objectForKey:@"statusDetail"]];
            [SCAppDelegate errorWithMessage:errorMessage];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading item schema: %@", [error localizedDescription]];
        [SCAppDelegate errorWithMessage:errorMessage];
        [_schemaLock unlock];
    }];
    _itemSchema = nil;
    [_schemaLock lock];
    [schemaOperation start];
}

- (void)populateInventoryWithData:(NSArray *)itemsData {
    self.detailViewController.detailItem = nil;

    [_schemaLock lock];
    _inventory = [[SCInventory alloc] initWithItems:itemsData andGame:_game andSchema:_itemSchema];
    [_schemaLock unlock];
    [_inventory sortItems];

    [self reloadInventory];
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([[notification object] isEqual:@"sorting"]) {
        [self sortInventory];
    } else if ([[notification object] isEqual:@"show_colors"]) {
        _inventory.showColors = [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"] boolValue];
        [self refreshInventory];
    }
}

- (void)reloadInventory
{
    [self.tableView setDataSource:_inventory];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];

        if ([_inventory.itemSections count] > 0 && [[_inventory.itemSections objectAtIndex:0] count] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    });
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
