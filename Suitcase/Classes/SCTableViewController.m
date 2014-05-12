//
//  SCTableViewController.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCTableViewController.h"

@implementation SCTableViewController

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] % 2) {
        cell.backgroundColor = [UIColor colorWithRed:0.37 green:0.42 blue:0.47 alpha:1.0];
    } else{
        cell.backgroundColor = [UIColor colorWithRed:0.4 green:0.45 blue:0.5 alpha:1.0];
    }
}

@end
