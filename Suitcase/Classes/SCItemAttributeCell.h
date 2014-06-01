//
//  SCItemAttributeCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

typedef NS_OPTIONS(NSUInteger, SCItemAttributeType) {
    SCItemAttributeTypeOrigin  = 1,
    SCItemAttributeTypeQuality = 2
};

@interface SCItemAttributeCell : UICollectionViewCell

@property (strong, nonatomic) id <SCItem> item;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic) SCItemAttributeType type;
@property (strong, nonatomic) IBOutlet UILabel *valueLabel;

+ (NSString *)attributeValueForType:(SCItemAttributeType)type andItem:(id <SCItem>)item;

- (void)empty;

@end
