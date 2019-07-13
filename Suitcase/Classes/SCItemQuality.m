//
//  SCItemQuality.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemQuality.h"

@implementation SCItemQuality

+ (SCItemQuality *)itemQualityFromItem:(id <SCItem>)item
{
    SCItemQuality *itemQuality = [[SCItemQuality alloc] init];
    itemQuality.color = item.qualityColor;
    itemQuality.name = item.qualityName;

    if (itemQuality.name == nil) {
        itemQuality.name = @"";
    }

    return itemQuality;
}

@end
