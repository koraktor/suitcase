//
//  SCCollectionViewFlowLayout.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemViewLayout.h"

@implementation SCItemViewLayout

- (void)awakeFromNib {
    [super awakeFromNib];

    self.minimumLineSpacing = 0.0;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray* attributesToReturn = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes* attributes in attributesToReturn) {
        if (nil == attributes.representedElementKind) {
            NSIndexPath* indexPath = attributes.indexPath;
            attributes.frame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
        }
    }
    return attributesToReturn;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes* currentItemAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];

    if (indexPath.section != 2) {
        return currentItemAttributes;
    }

    NSUInteger itemPosition = indexPath.item % 2;
    CGRect frame = currentItemAttributes.frame;

    if (indexPath.item > 1) {
        NSIndexPath* previousRowLeftItem = [NSIndexPath indexPathForItem:indexPath.item - itemPosition - 2 inSection:indexPath.section];
        NSIndexPath* previousRowRightItem = [NSIndexPath indexPathForItem:indexPath.item - itemPosition - 1 inSection:indexPath.section];

        CGRect previousRowLeftFrame = [self layoutAttributesForItemAtIndexPath:previousRowLeftItem].frame;
        CGRect previousRowRightFrame = [self layoutAttributesForItemAtIndexPath:previousRowRightItem].frame;

        frame.origin.y = MAX(CGRectGetMaxY(previousRowLeftFrame), CGRectGetMaxY(previousRowRightFrame));
    }

    if (indexPath.item % 2 == 0) {
        frame.origin.x = self.sectionInset.left;
    } else {
        NSIndexPath* leftIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
        CGRect leftFrame = [self layoutAttributesForItemAtIndexPath:leftIndexPath].frame;

        frame.origin.x = CGRectGetMaxX(leftFrame) + self.minimumInteritemSpacing;
    }

    currentItemAttributes.frame = frame;

    return currentItemAttributes;
}

@end
