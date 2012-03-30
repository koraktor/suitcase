//
//  SCDetailViewController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) SCItem *detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *itemImage;

@end
