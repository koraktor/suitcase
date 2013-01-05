//
//  SCNavigationControllerDelegate.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "SCNavigationControllerDelegate.h"

@implementation SCNavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if ([viewController class] != NSClassFromString(@"SCItemViewController")) {
        return;
    }

    [navigationController presentModalViewController:[[UIViewController alloc] init] animated:NO];
    [navigationController dismissModalViewControllerAnimated:NO];
    [UIViewController attemptRotationToDeviceOrientation];
}

@end
