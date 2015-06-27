//
//  SCReplaceDetailSegue.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCReplaceDetailSegue.h"

@implementation SCReplaceDetailSegue

- (void)perform {
    UISplitViewController *splitViewController = [self.sourceViewController splitViewController];
    UINavigationController *detailNavigationController = splitViewController.viewControllers[1];
    [detailNavigationController setToolbarHidden:YES animated:YES];
    [detailNavigationController setViewControllers:@[self.destinationViewController] animated:YES];
}

@end
