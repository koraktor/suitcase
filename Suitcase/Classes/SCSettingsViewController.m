//
//  SCSettingsViewController.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "IASKSettingsReader.h"
#import "IASKSwitch.h"

#import "SCSettingsViewController.h"

@implementation SCSettingsViewController

- (void)awakeFromNib
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleAction];
    }

    self.delegate = self;

    [super awakeFromNib];
}

- (IBAction)dismissSettings:(id)sender
{
    [self dismiss:sender];
}

- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewController
                        tableView:(UITableView *)tableView
        heightForHeaderForSection:(NSInteger)section {
    NSString *title = [self.settingsReader titleForSection:section];

    if (title == nil || [title length] == 0) {
        return 0.0;
    }

    return 50.0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController
                         tableView:(UITableView *)tableView
           viewForHeaderForSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 50.0)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, headerView.frame.size.width - 10, 50.0)];

    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.text = [self.settingsReader titleForSection:section];
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.font = [UIFont boldSystemFontOfSize:18.0];

    [headerView addSubview:headerLabel];

    return headerView;
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissModalViewControllerAnimated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];

    if ([specifier.type isEqualToString:kIASKPSGroupSpecifier]) {
        cell.detailTextLabel.textColor = [UIColor whiteColor];
    } else if ([specifier.type isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        ((IASKSwitch *)cell.accessoryView).onTintColor = [UIColor colorWithRed:0.3686 green:0.4196 blue:0.4745 alpha:1.0];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSString *footerText = [self tableView:tableView titleForFooterInSection:section];
    if (footerText == nil || [footerText length] == 0) {
        return 0.01;
    }

    return 100.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *footerText = [self tableView:tableView titleForFooterInSection:section];
    if (footerText == nil || [footerText length] == 0) {
        UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 0.0)];
        return footer;
    }

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 100.0)];
    footer.backgroundColor = [UIColor clearColor];
    footer.text = footerText;
    footer.textAlignment = NSTextAlignmentCenter;
    footer.textColor = [UIColor whiteColor];

    return footer;
}

@end
