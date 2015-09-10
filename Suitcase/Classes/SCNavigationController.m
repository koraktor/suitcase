//
//  SCNavigationController.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCNavigationController.h"

@implementation SCNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([self.topViewController isKindOfClass:NSClassFromString(@"SCWikiViewController")]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
