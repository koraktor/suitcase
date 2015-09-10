//
//  SCSteamIdFormController.m
//  Suitcase
//
//  Copyright (c) 2013-2014, Sebastian Staudt
//

#import "SCSplitViewController.h"

@implementation SCSplitViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.clearViewController = [self.viewControllers[1] topViewController];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end
