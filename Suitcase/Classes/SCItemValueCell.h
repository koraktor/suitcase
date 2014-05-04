//
//  SCItemValueCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCItemValueCell : UICollectionViewCell

@property (nonatomic, retain) NSString *name;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) NSString *value;
@property (strong, nonatomic) IBOutlet UILabel *valueLabel;

- (void)empty;

@end
