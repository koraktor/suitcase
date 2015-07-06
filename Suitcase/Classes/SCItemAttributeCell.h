//
//  SCItemAttributeCell.h
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCItem.h"

typedef NS_OPTIONS(NSUInteger, SCItemAttributeType) {
    SCItemAttributeTypeStyle      = 1,
    SCItemAttributeTypeOrigin     = 2,
    SCItemAttributeTypeQuality    = 4,
    SCItemAttributeTypeQuantity   = 8,
    SCItemAttributeTypeTradable   = 16,
    SCItemAttributeTypeMarketable = 32
};

@interface SCItemAttributeCell : UICollectionViewCell

@property (strong, nonatomic) id <SCItem> item;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic) SCItemAttributeType type;
@property (strong, nonatomic) IBOutlet UILabel *valueLabel;

+ (id)attributeValueForType:(SCItemAttributeType)type andItem:(id <SCItem>)item;

- (void)empty;

@end
