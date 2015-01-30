//
//  SCTableViewController.m
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"

#import "SCHeaderView.h"

#import "SCTableViewController.h"

@implementation SCTableViewController

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadStrings)
                                                 name:kSCLanguageSettingChanged
                                               object:nil];

    FAKIcon *wrenchIcon = [FAKFontAwesome wrenchIconWithSize:0.0];
    self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@" %@ ", [wrenchIcon characterCode]];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                                          forState:UIControlStateNormal];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withStyle:BPBarButtonItemStyleStandardDark];
    }

    self.refreshControl.frame = CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 40.0);

    [self.tableView registerClass:[SCHeaderView class] forHeaderFooterViewReuseIdentifier:@"SCHeaderView"];

    [self reloadStrings];
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] % 2) {
        cell.backgroundColor = [UIColor colorWithRed:0.37 green:0.42 blue:0.47 alpha:1.0];
    } else{
        cell.backgroundColor = [UIColor colorWithRed:0.4 green:0.45 blue:0.5 alpha:1.0];
    }
}

#pragma mark - Refresh Control

- (void)setRefreshControlTitle:(NSString *)title
{
    NSMutableAttributedString *refreshTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [refreshTitle setAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor]} range:NSMakeRange(0, refreshTitle.length)];
    self.refreshControl.attributedTitle = [refreshTitle copy];
}

- (IBAction)triggerRefresh:(id)sender
{
    [self setRefreshControlTitle:NSLocalizedString(@"Refreshing…", @"Refreshing…")];
}

#pragma mark - Language Support

- (void)reloadStrings
{
    [self setRefreshControlTitle:NSLocalizedString(@"Refresh", @"Refresh")];

    [self.tableView reloadData];
}

#pragma mark - Deallocation

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
