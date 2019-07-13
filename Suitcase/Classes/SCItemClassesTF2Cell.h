//
//  SCItemClassesTF2Cell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCClassImageView.h"

@interface SCItemClassesTF2Cell : UICollectionViewCell

+ (CGFloat)cellHeight;

@property (strong, nonatomic) IBOutlet SCClassImageView *classScoutImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classSoldierImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classPyroImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classDemomanImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classHeavyImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classEngineerImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classMedicImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classSniperImage;
@property (strong, nonatomic) IBOutlet SCClassImageView *classSpyImage;

@end
