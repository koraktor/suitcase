//
//  SCNavigationControllerDelegate.m
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
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
        [navigationController presentModalViewController:[[UIViewController alloc] init] animated:NO];
        [navigationController dismissModalViewControllerAnimated:NO];
        [UIViewController attemptRotationToDeviceOrientation];
    }

    _previousViewController = viewController;
}

@end
