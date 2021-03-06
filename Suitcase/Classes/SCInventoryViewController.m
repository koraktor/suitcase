//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2016, Sebastian Staudt
//

#import "IASKSettingsReader.h"

#import "SCAppDelegate.h"
#import "SCHeaderView.h"
#import "SCWebApiInventory.h"
#import "SCItem.h"
#import "SCItemViewController.h"
#import "SCItemCell.h"
#import "SCItemQuality.h"
#import "SCLanguage.h"
#import "SCSettingsViewController.h"
#import "SCSteamIdFormController.h"

#import "SCInventoryViewController.h"

@interface SCInventoryViewController () {
    NSString *_lastItemFilter;
}
@end

@implementation SCInventoryViewController

NSString *const kSCInventorySearchNoResults = @"kSCInventorySearchNoResults";
NSString *const kSCInventorySearchPlaceholder = @"kSCInventorySearchPlaceholder";

- (void)awakeFromNib
{
    [super awakeFromNib];

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
                                             selector:@selector(reloadInventory)
                                                 name:@"inventoryLoaded"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sortInventory)
                                                 name:@"sortInventory"
                                               object:nil];
}

- (void)settingsChanged:(NSNotification *)notification {
    NSString *settingsKey = notification.userInfo.allKeys[0];
    if ([settingsKey isEqual:@"sorting"]) {
        [self sortInventory];
    } else if ([settingsKey isEqual:@"show_colors"]) {
        _inventory.showColors = [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_colors"] boolValue];
        [self refreshInventory];
    } else if ([settingsKey isEqualToString:@"language"]) {
        [self reloadStrings];
    }
}

- (void)setInventory:(id <SCInventory>)inventory
{
    if (inventory != _inventory) {
        _inventory = inventory;

        self.navigationItem.title = self.inventory.game.name;

        [self reloadInventory];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *placeholderText = NSLocalizedString(kSCInventorySearchPlaceholder, kSCInventorySearchPlaceholder);

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.searchBar.placeholder = placeholderText;
    } else {
        for (UIView *view in self.searchBar.subviews) {
            for (UIView *subview in view.subviews) {
                if ([subview isKindOfClass:[UITextField class]]) {
                    NSAttributedString *placeholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                                      attributes:@{ NSForegroundColorAttributeName: UIColor.lightGrayColor }];
                    ((UITextField *)subview).attributedPlaceholder = placeholder;
                }
            }
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [SCAbstractInventory setCurrentInventory:nil];
}

#pragma mark - Search Bar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(searchItems:)
                                               object:_lastItemFilter];

    _lastItemFilter = searchText;

    if ([searchText isEqualToString:@""]) {
        [self searchItems:searchText];
    } else {
        [self performSelector:@selector(searchItems:)
                   withObject:searchText
                   afterDelay:0.5];
    }
}

- (void)searchItems:(NSString *)itemFilter
{
    if ([itemFilter isEqualToString:@""]) {
        self.items = self.inventory.items;
    } else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(id <SCItem> item, NSDictionary *bindings) {
            NSRange range = [item.name rangeOfString:itemFilter options:NSCaseInsensitiveSearch];
            return range.location != NSNotFound;
        }];
        self.items = [self.inventory.items filteredArrayUsingPredicate:filterPredicate];
    }

    [self sortItems];
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        [self.searchBar resignFirstResponder];

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id <SCItem> item = [[self.itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        ((SCItemViewController *)segue.destinationViewController).item = item;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (void)reloadInventory
{
    self.items = self.inventory.items;

    if ([self.inventory.items count] > 0) {
        [self sortItems];
    }

    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, self.searchBar.frame.size.height)];

    if (self.refreshControl.isRefreshing) {
        [self setRefreshControlTitle:NSLocalizedString(@"Refresh", @"Refresh")];

        [self.refreshControl endRefreshing];
    }
}

- (void)refreshInventory
{
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        if ([cell isMemberOfClass:[SCItemCell class]]) {
            ((SCItemCell *) cell).showColors = _inventory.showColors;
        }
    }

    [self.tableView reloadData];
}

- (void)reloadStrings {
    self.items = self.inventory.items;

    if ([self.inventory.items count] > 0) {
        [self sortItems];
    }

    [super reloadStrings];
}

- (void)sortInventory
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSIndexSet *oldSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections)];
        [self sortItems];
        NSIndexSet *newSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.itemSections.count)];
        [self.tableView beginUpdates];
        [self.tableView deleteSections:oldSections withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertSections:newSections withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    } else {
        [self sortItems];
        [self.tableView reloadData];
    }

    if ([self.itemSections count] > 0 && [[self.itemSections objectAtIndex:0] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)sortItems
{
    NSString *sortOrder = [self sortOrder];

    if (sortOrder == nil || [sortOrder isEqualToString:@"position"]) {
        self.itemSections = [NSArray arrayWithObject:[self.items sortedArrayUsingComparator:^NSComparisonResult(id <SCItem> item1, id <SCItem> item2) {
            return [item1.position compare:item2.position];
        }]];
    } else {
        NSMutableArray *newItemSections;
        if ([sortOrder isEqualToString:@"name"]) {
            newItemSections = [NSMutableArray arrayWithCapacity:[SCAbstractInventory alphabet].count + 1];
            for (NSUInteger i = 0; i <= [SCAbstractInventory alphabet].count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            for (id<SCItem> item in self.items) {
                NSString *start = [[item.name substringToIndex:1] uppercaseString];
                NSUInteger nameIndex = [[SCAbstractInventory alphabet] indexOfObject:start];
                if (nameIndex == NSNotFound) {
                    nameIndex = -1;
                }
                [newItemSections[nameIndex + 1] addObject:item];
            };
        } else if ([sortOrder isEqual:@"origin"]) {
            newItemSections = [NSMutableArray arrayWithCapacity:self.inventory.origins.count];
            for (NSUInteger i = 0; i < self.inventory.origins.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            for (id<SCItem> item in self.items) {
                [newItemSections[[item.originIndex unsignedIntegerValue]] addObject:item];
            };
        } else if ([sortOrder isEqualToString:@"quality"]) {
            NSMutableDictionary *itemQualities = [NSMutableDictionary dictionary];
            for (id<SCItem> item in self.items) {
                NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                if ([itemQualities objectForKey:qualityName] == nil) {
                    SCItemQuality *itemQuality = [SCItemQuality itemQualityFromItem:item];
                    itemQualities[itemQuality.name] = itemQuality;
                }
            };
            self.itemQualities = [NSDictionary dictionaryWithDictionary:itemQualities];

            newItemSections = [NSMutableArray arrayWithCapacity:self.itemQualities.count];
            for (NSUInteger i = 0; i < self.itemQualities.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            for (id<SCItem> item in self.items) {
                NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                NSUInteger qualityIndex = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] indexOfObject:qualityName];
                [newItemSections[qualityIndex] addObject:item];
            };
        } else if ([sortOrder isEqualToString:@"type"]) {
            NSMutableArray *itemTypes = [NSMutableArray array];
            for (id<SCItem> item in self.items) {
                if (![itemTypes containsObject:item.itemType]) {
                    [itemTypes addObject:item.itemType];
                }
            };
            self.itemTypes = [itemTypes sortedArrayUsingSelector:@selector(compare:)];

            newItemSections = [NSMutableArray arrayWithCapacity:_itemTypes.count];
            for (NSUInteger i = 0; i < self.itemTypes.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            for (id<SCItem> item in self.items) {
                NSUInteger typeIndex = [self.itemTypes indexOfObject:item.itemType];
                [newItemSections[typeIndex] addObject:item];
            };
        }

        NSMutableArray *sortedItemSections = [NSMutableArray arrayWithCapacity:newItemSections.count];
        for (NSArray *section in newItemSections) {
            [sortedItemSections addObject:[section sortedArrayUsingComparator:^NSComparisonResult(id <SCItem> item1, id <SCItem> item2) {
                return [item1.name compare:item2.name];
            }]];
        };
        self.itemSections = [NSArray arrayWithArray:sortedItemSections];
    }
}

- (NSString *)sortOrder
{
    NSString *sortOrder = [[NSUserDefaults standardUserDefaults] valueForKey:@"sorting"];

    if ([self.inventory class] == NSClassFromString(@"SCCommunityInventory") &&
        [sortOrder isEqualToString:@"origin"]) {
        sortOrder = @"position";
    }

    return sortOrder;
}

- (UIColor *)colorForQualityIndex:(NSInteger)index
{
    NSString *qualityName = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:index];

    return ((SCItemQuality *)self.itemQualities[qualityName]).color;
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < self.searchBar.frame.size.height) {
        [UIView animateWithDuration:0.3 animations:^{
            self.searchBar.alpha = 1.0;
        }];
    } else if (self.searchBar.alpha == 1.0) {
        self.searchBar.alpha = 0.0;
        [self.searchBar endEditing:YES];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.items.count == 0) {
        return 1;
    }

    return self.itemSections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.items.count == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoResultsCell"];
        cell.textLabel.text = NSLocalizedString(kSCInventorySearchNoResults, kSCInventorySearchNoResults);

        return cell;
    }

    id <SCItem> item = self.itemSections[indexPath.section][indexPath.row];

    SCItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell"];
    cell.item = item;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.items.count == 0) {
        return 1;
    }

    return ((NSArray *)self.itemSections[section]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.items.count == 0 || [[self.itemSections objectAtIndex:section] count] == 0) {
        return nil;
    }

    NSString *sortOrder = [self sortOrder];

    if ([self.inventory class] == NSClassFromString(@"SCCommunityInventory") && [sortOrder isEqualToString:@"origin"]) {
        sortOrder = @"position";
    }

    if ([sortOrder isEqual:@"name"]) {
        return [SCAbstractInventory alphabetWithNumbers][section];
    } else if ([sortOrder isEqual:@"origin"]) {
        return [self.inventory originNameForIndex:section];
    } else if ([sortOrder isEqual:@"quality"]) {
        return [[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)][section];
    } else if ([sortOrder isEqual:@"type"]) {
        return self.itemTypes[section];
    } else {
        return nil;
    }
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];

    if (title == nil || [title isEqualToString:@""]) {
        return 0.0;
    }

    return 20.0;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    SCHeaderView *headerView = (SCHeaderView *)view;
    headerView.textLabel.adjustsFontSizeToFitWidth = YES;
    headerView.textLabel.textAlignment = NSTextAlignmentCenter;
    headerView.textLabel.center = headerView.center;

    if (self.inventory.showColors && [[self sortOrder] isEqualToString:@"quality"]) {
        headerView.backgroundColor = [self colorForQualityIndex:section];
    } else {
        headerView.backgroundColor = SCHeaderView.defaultBackgroundColor;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];

    if (title == nil || [title isEqualToString:@""]) {
        return nil;
    }

    SCHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"SCHeaderView"];
    headerView.textLabel.text = title;
    headerView.textLabel.textAlignment = NSTextAlignmentCenter;

    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    if ([cell isKindOfClass:[SCItemCell class]]) {
        ((SCItemCell *)cell).showColors = self.inventory.showColors;
    }
}

#pragma mark - Refresh Control

- (IBAction)triggerRefresh:(id)sender {
    [super triggerRefresh:sender];

    [NSThread detachNewThreadSelector:@selector(reload) toTarget:self.inventory withObject:nil];
}

#pragma mark - Sharing

- (NSURL *)sharedURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://steamcommunity.com/profiles/%@/inventory#%@",
                                 self.inventory.steamId64, self.inventory.game.appId]];
}

@end
