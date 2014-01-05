//
//  SCNavigationControllerDelegate.m
//  Suitcase
//
//  Copyright (c) 2013-2014, Sebastian Staudt
//

#import "SCNavigationControllerDelegate.h"

@interface SCNavigationControllerDelegate () {
    UIViewController *_previousViewController;
}
@end

@implementation SCNavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if ([_previousViewController class] == NSClassFromString(@"SCWikiViewController")) {
        [navigationController presentViewController:[[UIViewController alloc] init] animated:NO completion:nil];
        [navigationController dismissViewControllerAnimated:NO completion:nil];
        [UIViewController attemptRotationToDeviceOrientation];
    }

    _previousViewController = viewController;
}

@end
