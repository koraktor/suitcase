//
//  SCSettingsViewController.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "BPBarButtonItem.h"

#import "SCSettingsViewController.h"

@implementation SCSettingsViewController

- (void)awakeFromNib
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.leftBarButtonItem withStyle:BPBarButtonItemStyleAction];
    }

    [super awakeFromNib];
}

- (IBAction)dismissSettings:(id)sender {
    [self dismiss:sender];
}

@end
