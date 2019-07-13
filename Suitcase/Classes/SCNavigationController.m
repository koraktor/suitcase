//
//  SCNavigationController.m
//  Suitcase
//
//  Copyright (c) 2014-2016, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "SCSharingController.h"

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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController conformsToProtocol:@protocol(SCSharingController)]) {
        FAKIcon *shareIcon = [FAKFontAwesome shareSquareOIconWithSize:0.0];
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:shareIcon.characterCode
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self action:@selector(share)];
        shareButton.title = [NSString stringWithFormat:@" %@ ", [shareIcon characterCode]];
        [shareButton setTitleTextAttributes:@{NSFontAttributeName:[FAKFontAwesome iconFontWithSize:20.0]}
                                   forState:UIControlStateNormal];

        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            [BPBarButtonItem customizeBarButtonItem:shareButton withStyle:BPBarButtonItemStyleStandardDark];
        }

        NSMutableArray *barButtonItems = [viewController.navigationItem.rightBarButtonItems mutableCopy];
        if (barButtonItems == nil) {
            barButtonItems = [NSMutableArray arrayWithCapacity:1];
        }
        [barButtonItems addObject:shareButton];
        viewController.navigationItem.rightBarButtonItems = barButtonItems;
    }

    [super pushViewController:viewController animated:animated];
}

#pragma mark - Sharing

- (void)share {
    id<SCSharingController> sharingController = (id<SCSharingController>)self.viewControllers.lastObject;

    UIActivityViewController *shareController = [[UIActivityViewController alloc]
                                                 initWithActivityItems:@[sharingController.sharedURL]
                                                 applicationActivities:nil];

    [shareController setValue:@"Sharing" forKey:@"subject"];
    shareController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];

    [self presentViewController:shareController animated:YES completion:nil];
}

@end
