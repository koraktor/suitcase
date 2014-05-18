//
//  SCItemAttributeCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "FAKFontAwesome.h"

#import "SCItemAttributeCell.h"

@implementation SCItemAttributeCell

NSString *const kSCItemOrigin = @"kSCItemOrigin";
NSString *const kSCItemQuality = @"kSCItemQuality";

static NSAttributedString *kOriginIcon;
static NSAttributedString *kQualityIcon;

+ (void)initialize {
    kOriginIcon = [[FAKFontAwesome asteriskIconWithSize:16.0] attributedString];
    kQualityIcon = [[FAKFontAwesome starIconWithSize:16.0] attributedString];
}

+ (NSString *)attributeValueForType:(SCItemAttributeType)type andItem:(id <SCItem>)item {
    switch (type) {
        case SCItemAttributeTypeOrigin: return item.origin;
        case SCItemAttributeTypeQuality: return item.qualityName;
        default: return nil;
    }
}

- (void)empty {
    self.nameLabel = nil;
    self.valueLabel = nil;
}

- (void)setType:(SCItemAttributeType)type {
    NSAttributedString *icon;
    NSString *name;
    switch (type) {
        case SCItemAttributeTypeOrigin:
            icon = kOriginIcon;
            name = NSLocalizedString(kSCItemOrigin, kSCItemOrigin);
            break;
        case SCItemAttributeTypeQuality:
            icon = kQualityIcon;
            name = NSLocalizedString(kSCItemQuality, kSCItemQuality);
    }

    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithAttributedString:icon];
    [labelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", name]]];
    self.nameLabel.attributedText = labelText;
    [self.nameLabel sizeToFit];

    NSString *value = [SCItemAttributeCell attributeValueForType:type andItem:self.item];
    self.valueLabel.text = NSLocalizedString(value, value);
    [self.valueLabel sizeToFit];
}

@end
