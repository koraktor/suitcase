//
//  SCItemImageCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

@interface SCItemImageCell : UICollectionViewCell

+ (CGFloat)heightOfCellForImage:(UIImage *)image;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) id <SCItem> item;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

- (void)adjustToImageSize;
- (void)refresh;

@end
