//
//  SCSettingsViewController.m
//  Suitcase
//
//  Copyright (c) 2013-2014, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "IASKSettingsReader.h"
#import "IASKSwitch.h"

#import "SCLanguage.h"
#import "SCSettingsReader.h"

#import "SCSettingsViewController.h"

@interface SCSettingsViewController () {
    SCSettingsReader *_settingsReader;
}
@end

@implementation SCSettingsViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleAction];
    }

    self.delegate = self;
    self.showCreditsFooter = NO;
    self.showDoneButton = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadStrings)
                                                 name:kSCLanguageSettingChanged
                                               object:nil];

    [self reloadStrings];
}

- (IBAction)dismissSettings:(id)sender
{
    [self dismiss:sender];
}

- (IASKSettingsReader *)settingsReader {
    if (_settingsReader == nil) {
        _settingsReader = [[SCSettingsReader alloc] initWithFile:self.file];
    }

    return _settingsReader;
}

- (void)reloadStrings
{
    self.title = NSLocalizedString(@"Settings", @"Settings");

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        ((UIBarButtonItem *)self.toolbarItems.firstObject).title = NSLocalizedString(@"Done", @"Done");
    } else {
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Done", @"Done");
    }
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
    headerLabel.textColor = [UIColor colorWithRed:0.3686 green:0.4196 blue:0.4745 alpha:1.0];
    headerLabel.font = [UIFont boldSystemFontOfSize:18.0];

    [headerView addSubview:headerLabel];

    return headerView;
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];

    cell.backgroundColor = [UIColor whiteColor];
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
        return 0.0;
    }

    return 100.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *footerText = [self tableView:tableView titleForFooterInSection:section];
    if (footerText == nil || [footerText length] == 0) {
        return nil;
    }

    CGRect footerSize = CGRectMake(0.0, 0.0, tableView.frame.size.width, 100.0);

    NSShadow *logoShadow = [NSShadow new];
    logoShadow.shadowColor = [UIColor colorWithWhite:0.7 alpha:0.9];
    logoShadow.shadowOffset = CGSizeMake(0.0, -2.0);

    FAKFontAwesome *steamLogo = [FAKFontAwesome steamIconWithSize:100.0];
    [steamLogo addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.9 alpha:0.7]];
    [steamLogo addAttribute:NSShadowAttributeName value:logoShadow];
    UIImage *steamLogoImage = [steamLogo imageWithSize:CGSizeMake(140.0, 100.0)];
    UIImageView *steamLogoView = [[UIImageView alloc] initWithFrame:footerSize];
    steamLogoView.contentMode = UIViewContentModeCenter;
    steamLogoView.image = steamLogoImage;

    UILabel *steamLabel = [[UILabel alloc] initWithFrame:footerSize];
    steamLabel.backgroundColor = [UIColor clearColor];
    steamLabel.text = footerText;
    steamLabel.textAlignment = NSTextAlignmentCenter;
    steamLabel.textColor = [UIColor colorWithRed:0.3686 green:0.4196 blue:0.4745 alpha:1.0];

    UIView *footerView = [[UIView alloc] initWithFrame:footerSize];
    [footerView addSubview:steamLogoView];
    [footerView addSubview:steamLabel];

    return footerView;
}

@end
