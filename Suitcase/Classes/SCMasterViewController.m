//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCMasterViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "ASIHTTPRequest.h"
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "SCAppDelegate.h"
#import "SCInventory.h"
#import "SCItemViewController.h"
#import "SCItem.h"
#import "SCSchema.h"
#import "UIImageView+ASIHTTPRequest.h"

@interface SCMasterViewController () {
    SCInventory *_inventory;
	SCSchema *_itemSchema;
    NSLock *_schemaLock;
}
@end

@implementation SCMasterViewController

@synthesize detailViewController = _detailViewController;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSchema) name:@"loadSchema" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadInventory) name:@"loadInventory" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:kIASKAppSettingChanged object:nil];
    
    _schemaLock = [[NSLock alloc] init];

    [super awakeFromNib];
}

- (void)loadInventory {    
    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSURL *inventoryUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001?steamid=%@&key=%@", steamId64, [SCAppDelegate apiKey]]];
    __unsafe_unretained __block ASIHTTPRequest *inventoryRequest = [ASIHTTPRequest requestWithURL:inventoryUrl];
    [inventoryRequest setCompletionBlock:^{
        NSError *error = nil;
        NSDictionary *inventoryResponse = [[NSJSONSerialization JSONObjectWithData:[inventoryRequest responseData] options:0 error:&error] objectForKey:@"result"];
        if ([[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSArray *itemsResponse = [inventoryResponse objectForKey:@"items"];
            [NSThread detachNewThreadSelector:@selector(populateInventoryWithData:) toTarget:self withObject:itemsResponse];
        } else {
            NSString *errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [inventoryResponse objectForKey:@"statusDetail"]]; 
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
    [inventoryRequest setFailedBlock:^{
        NSError *error = [inventoryRequest error];
        NSString *errorMessage;
        if (error == nil) {
            errorMessage = [inventoryRequest responseStatusMessage];
        } else {
            errorMessage = [error localizedDescription];
        }
        NSLog(@"Error loading inventory contents: %@", errorMessage);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading the inventory contents" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [inventoryRequest startAsynchronous];
}

- (void)loadSchema {
    NSURL *schemaUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_440/GetSchema/v0001?key=%@&language=%@", [SCAppDelegate apiKey], [[NSLocale preferredLanguages] objectAtIndex:0]]];
    __unsafe_unretained __block ASIHTTPRequest *schemaRequest = [ASIHTTPRequest requestWithURL:schemaUrl];
    [schemaRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    [schemaRequest setCompletionBlock:^{
        NSError *error = nil;
        NSDictionary *schemaResponse = [[NSJSONSerialization JSONObjectWithData:[schemaRequest responseData] options:0 error:&error] objectForKey:@"result"];
        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            _itemSchema = [[SCSchema alloc] initWithDictionary:schemaResponse];
        } else {
            NSString *errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [schemaResponse objectForKey:@"statusDetail"]]; 
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        [_schemaLock unlock];
    }];
    [schemaRequest setFailedBlock:^{
        NSError *error = [schemaRequest error];
        NSString *errorMessage;
        if (error == nil) {
            errorMessage = [schemaRequest responseStatusMessage];
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
    _inventory = [[SCInventory alloc] initWithItems:itemsData andSchema:_itemSchema];
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
        [_inventory sortItems];
        [self.tableView reloadData];

        if ([_inventory.itemSections count] > 0 && [[_inventory.itemSections objectAtIndex:0] count] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    } else if ([[notification object] isEqual:@"show_colors"]) {
        [self.tableView reloadData];
    }
}

- (IBAction)showSteamIdForm:(id)sender {
    [self performSegueWithIdentifier:@"SteamIDForm" sender:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.detailViewController = (SCItemViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.navigationItem.title = NSLocalizedString(self.navigationItem.title, @"Inventory title");

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"] == nil) {
        [self showSteamIdForm:self];
    }
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
        IASKAppSettingsViewController *settingsController = (IASKAppSettingsViewController *)[navigationController.childViewControllers objectAtIndex:0];
        settingsController.title = NSLocalizedString(@"Settings", @"Settings");
        settingsController.delegate = self;
        settingsController.showCreditsFooter = NO;
        settingsController.showDoneButton = YES;
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissModalViewControllerAnimated:YES];
}

@end
