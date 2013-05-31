//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import <QuartzCore/QuartzCore.h>

#import "BPBarButtonItem.h"
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
}
@end

@implementation SCInventoryViewController

@synthesize detailViewController = _detailViewController;
@synthesize inventory = _inventory;

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
                                             selector:@selector(reloadInventory)
                                                 name:@"reloadInventory"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshInventory)
                                                 name:@"refreshInventory"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sortInventory)
                                                 name:@"sortInventory"
                                               object:nil];

    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];

    self.navigationItem.rightBarButtonItem.title = FAKIconWrench;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FontAwesomeKit fontWithSize:20]}
                                                          forState:UIControlStateNormal];
    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];

    [super awakeFromNib];
}

- (NSString *)currentLanguage
{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([[notification object] isEqual:@"sorting"]) {
        [self sortInventory];
    } else if ([[notification object] isEqual:@"show_colors"]) {
        _inventory.showColors = [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"] boolValue];
        [self refreshInventory];
    }
}

- (void)setInventory:(SCInventory *)inventory
{
    _inventory = inventory;
    self.detailViewController.detailItem = nil;

    UIViewController *modal = [[[self presentedViewController] childViewControllers] objectAtIndex:0];
    if ([modal class] == NSClassFromString(@"SCSteamIdFormController")) {
        [(SCSteamIdFormController *)modal dismissForm:self];
    }

    NSCondition *schemaCondition = [[NSCondition alloc] init];

    AFJSONRequestOperation *schemaOperation = [SCSchema schemaOperationForInventory:_inventory
                                                                        andLanguage:[self currentLanguage]
                                                                       andCondition:schemaCondition];
    if (schemaOperation != nil) {
        [schemaOperation setFailureCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        [schemaOperation setSuccessCallbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        [schemaOperation start];
    }

    [schemaCondition lock];

    while (_inventory.schema == nil) {
        [schemaCondition wait];
    }
    [_inventory sortItems];

    [schemaCondition unlock];

    [self reloadInventory];
}

- (void)reloadInventory
{
    [self.tableView setDataSource:_inventory];
    [self.tableView setDelegate:self];

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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView.dataSource == self) {
        return 0.0;
    }

    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];

    if (title == nil) {
        return 0.0;
    }

    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView.dataSource == self) {
        return nil;
    }

    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];

    if (title == nil) {
        return nil;
    }

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 20.0)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, headerView.frame.size.width, 20.0)];

    headerLabel.backgroundColor = UIColor.clearColor;
    headerLabel.text = title;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.font = [UIFont boldSystemFontOfSize:18.0];

    headerView.alpha = 0.8f;
    headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"header_gradient"]];
    headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    headerView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    headerView.layer.shadowOpacity = 0.5f;
    headerView.layer.shadowRadius = 3.25f;
    headerView.layer.masksToBounds = NO;

    [headerView addSubview:headerLabel];

    return headerView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
