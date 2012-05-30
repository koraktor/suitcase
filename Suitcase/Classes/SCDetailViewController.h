//
//  SCDetailViewController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCClassImageView.h"
#import "SCItem.h"

@interface SCDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) SCItem *detailItem;

@property (strong, nonatomic) IBOutlet SCClassImageView *classScoutImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classSoldierImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classPyroImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classDemomanImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classHeavyImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classEngineerImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classMedicImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classSniperImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classSpyImage;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIView *imageFrame;
@property (strong, nonatomic) IBOutlet UIImageView *itemImage;
@property (strong, nonatomic) IBOutlet UILabel *levelLabel;
@property (strong, nonatomic) IBOutlet UILabel *originLabel;
@property (strong, nonatomic) IBOutlet UILabel *qualityLabel;
@property (strong, nonatomic) IBOutlet UILabel *quantityLabel;

@end
