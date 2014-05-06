//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "IASKSettingsReader.h"

#import "SCAppDelegate.h"
#import "SCWebApiInventory.h"
#import "SCItem.h"
#import "SCItemViewController.h"
#import "SCItemCell.h"
#import "SCSettingsViewController.h"
#import "SCSteamIdFormController.h"

#import "SCInventoryViewController.h"

@implementation SCInventoryViewController

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
                                             selector:@selector(refreshInventory)
                                                 name:@"showColorsChanged"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sortInventory)
                                                 name:@"sortInventory"
                                               object:nil];

    FAKIcon *wrenchIcon = [FAKFontAwesome wrenchIconWithSize:0.0];
    self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [wrenchIcon characterCode]];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                          forState:UIControlStateNormal];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];
    }

    self.tableView.delegate = self;

    [super awakeFromNib];
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([[notification object] isEqual:@"sorting"]) {
        [self sortInventory];
    } else if ([[notification object] isEqual:@"show_colors"]) {
        _inventory.showColors = [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"] boolValue];
        [self refreshInventory];
    }
}

- (void)setInventory:(id <SCInventory>)inventory
{
    if (inventory != _inventory) {
        _inventory = inventory;

        self.navigationItem.title = self.inventory.game.name;

        if ([inventory.items count] > 0) {
            [_inventory sortItems];
            self.tableView.dataSource = _inventory;

            if ([_inventory.itemSections count] > 0 && [[_inventory.itemSections objectAtIndex:0] count] > 0) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
    }
}

#pragma mark - Table View

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id <SCItem> item = [[_inventory.itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        ((SCItemViewController *)segue.destinationViewController).detailItem = item;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        SCSettingsViewController *settingsController = (SCSettingsViewController *)[navigationController.childViewControllers objectAtIndex:0];
        settingsController.title = NSLocalizedString(@"Settings", @"Settings");
        settingsController.showCreditsFooter = NO;
        settingsController.showDoneButton = NO;
    }
}

- (void)refreshInventory
{
    for (SCItemCell *cell in [self.tableView visibleCells]) {
        cell.showColors = _inventory.showColors;
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
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];

    headerLabel.backgroundColor = UIColor.clearColor;
    headerLabel.text = title;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = UIColor.whiteColor;

    UIColor *backgroundColor = [UIColor colorWithRed:0.5372 green:0.6196 blue:0.7294 alpha:0.63];
    CGFloat fontSize = 16.0;

    headerView.alpha = 0.8f;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
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
        headerLabel.font = [UIFont systemFontOfSize:fontSize];
        headerView.backgroundColor = backgroundColor;
    }

    [headerView addSubview:headerLabel];

    return headerView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
