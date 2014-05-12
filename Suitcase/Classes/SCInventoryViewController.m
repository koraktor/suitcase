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
#import "SCItemQuality.h"
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

    [super awakeFromNib];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            self.items = self.inventory.items;
            [self sortItems];

            if (self.itemSections.count > 0 && [self.itemSections[0] count] > 0) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView setContentOffset:CGPointMake(0, self.searchBar.frame.size.height)];
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
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id <SCItem> item = [[self.itemSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
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

    [self.tableView reloadData];
}

- (void)sortInventory
{
    [self sortItems];
    [self.tableView reloadData];

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
            [self.items enumerateObjectsUsingBlock:^(id <SCItem> item, NSUInteger idx, BOOL *stop) {
                NSString *start = [[item.name substringToIndex:1] uppercaseString];
                NSUInteger nameIndex = [[SCAbstractInventory alphabet] indexOfObject:start];
                if (nameIndex == NSNotFound) {
                    nameIndex = -1;
                }
                [newItemSections[nameIndex + 1] addObject:item];
            }];
        } else if ([sortOrder isEqual:@"origin"]) {
            newItemSections = [NSMutableArray arrayWithCapacity:self.inventory.origins.count];
            for (NSUInteger i = 0; i < self.inventory.origins.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(id <SCItem> item, NSUInteger idx, BOOL *stop) {
                [newItemSections[[item.originIndex unsignedIntegerValue]] addObject:item];
            }];
        } else if ([sortOrder isEqualToString:@"quality"]) {
            NSMutableDictionary *itemQualities = [NSMutableDictionary dictionary];
            [self.items enumerateObjectsUsingBlock:^(id <SCItem> item, NSUInteger idx, BOOL *stop) {
                NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                if ([itemQualities objectForKey:qualityName] == nil) {
                    SCItemQuality *itemQuality = [SCItemQuality itemQualityFromItem:item];
                    itemQualities[itemQuality.name] = itemQuality;
                }
            }];
            self.itemQualities = [NSDictionary dictionaryWithDictionary:itemQualities];

            newItemSections = [NSMutableArray arrayWithCapacity:self.itemQualities.count];
            for (NSUInteger i = 0; i < self.itemQualities.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(id <SCItem> item, NSUInteger idx, BOOL *stop) {
                NSString *qualityName = (item.qualityName == nil) ? @"" : item.qualityName;
                NSUInteger qualityIndex = [[[self.itemQualities allKeys] sortedArrayUsingSelector:@selector(compare:)] indexOfObject:qualityName];
                [newItemSections[qualityIndex] addObject:item];
            }];
        } else if ([sortOrder isEqualToString:@"type"]) {
            NSMutableArray *itemTypes = [NSMutableArray array];
            [self.items enumerateObjectsUsingBlock:^(id <SCItem> item, NSUInteger idx, BOOL *stop) {
                if (![itemTypes containsObject:item.itemType]) {
                    [itemTypes addObject:item.itemType];
                }
            }];
            self.itemTypes = [itemTypes sortedArrayUsingSelector:@selector(compare:)];

            newItemSections = [NSMutableArray arrayWithCapacity:_itemTypes.count];
            for (NSUInteger i = 0; i < self.itemTypes.count; i ++) {
                [newItemSections addObject:[NSMutableArray array]];
            }
            [self.items enumerateObjectsUsingBlock:^(id <SCItem> item, NSUInteger idx, BOOL *stop) {
                NSUInteger typeIndex = [self.itemTypes indexOfObject:item.itemType];
                [newItemSections[typeIndex] addObject:item];
            }];
        }

        NSMutableArray *sortedItemSections = [NSMutableArray arrayWithCapacity:newItemSections.count];
        [newItemSections enumerateObjectsUsingBlock:^(NSArray *section, NSUInteger idx, BOOL *stop) {
            [sortedItemSections addObject:[section sortedArrayUsingComparator:^NSComparisonResult(id <SCItem> item1, id <SCItem> item2) {
                return [item1.name compare:item2.name];
            }]];
        }];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];

    if (title == nil || [title isEqualToString:@""]) {
        return nil;
    }

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 20.0)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.text = title;
    headerLabel.textAlignment = NSTextAlignmentCenter;

    UIColor *backgroundColor;
    if (self.inventory.showColors && [[self sortOrder] isEqualToString:@"quality"]) {
        backgroundColor = [self colorForQualityIndex:section];
    } else {
        backgroundColor = [UIColor colorWithRed:0.5372 green:0.6196 blue:0.7294 alpha:0.63];
    }

    CGFloat white;
    if (![backgroundColor getWhite:&white alpha:nil]) {
        const CGFloat *colorComponents = CGColorGetComponents(backgroundColor.CGColor);
        white = ((colorComponents[0] * 299) + (colorComponents[1] * 587) + (colorComponents[2] * 114)) / 1000;
    }
    white = (white < 0.7) ? 0.9 : 0.1;
    headerLabel.textColor = [UIColor colorWithWhite:white alpha:1.0];

    CGFloat fontSize = 16.0;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        headerView.alpha = 0.8f;
        headerLabel.backgroundColor = UIColor.clearColor;

        headerLabel.font = [UIFont boldSystemFontOfSize:fontSize];

        UIColor *gradientColor;
        if (self.inventory.showColors) {
            struct CGColorSpace *colorSpace = CGColorGetColorSpace(backgroundColor.CGColor);
            if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome) {
                [backgroundColor getWhite:&white alpha:nil];
                gradientColor = [UIColor colorWithWhite:white - 0.3 alpha:1.0];
            } else {
                CGFloat alpha;
                CGFloat brightness;
                CGFloat hue;
                CGFloat saturation;
                [backgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                brightness -= 0.3;
                gradientColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
            }
        } else {
            gradientColor = [UIColor colorWithRed:0.2118 green:0.2392 blue:0.2706 alpha:1.0];
        }

        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = headerView.bounds;
        gradient.colors = @[ (id)backgroundColor.CGColor, (id)gradientColor.CGColor ];
        [headerView.layer addSublayer:gradient];

        headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
        headerView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        headerView.layer.shadowOpacity = 0.5f;
        headerView.layer.shadowRadius = 3.25f;
        headerView.layer.masksToBounds = NO;
    } else {
        headerLabel.font = [UIFont systemFontOfSize:fontSize];
        headerView.alpha = 1.0f;
        headerView.backgroundColor = backgroundColor;
    }

    [headerView addSubview:headerLabel];

    return headerView;
}

@end
