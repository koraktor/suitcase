//
//  SCItemAttributeCell.m
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import "FAKFontAwesome.h"

#import "SCItemAttributeCell.h"

@implementation SCItemAttributeCell

NSString *const kSCItemMarketable = @"kSCItemMarketable";
NSString *const kSCItemOrigin = @"kSCItemOrigin";
NSString *const kSCItemQuality = @"kSCItemQuality";
NSString *const kSCItemQuantity = @"kSCItemQuantity";
NSString *const kSCItemStyle = @"kSCItemStyle";
NSString *const kSCItemTradable = @"kSCItemTradable";

static NSAttributedString *kMarketableIcon;
static NSAttributedString *kOriginIcon;
static NSAttributedString *kQualityIcon;
static NSAttributedString *kQuantityIcon;
static NSAttributedString *kStyleIcon;
static NSAttributedString *kTradableIcon;

static NSAttributedString *kNoIcon;
static NSAttributedString *kYesIcon;

+ (void)initialize {
    kMarketableIcon = [[FAKFontAwesome moneyIconWithSize:16.0] attributedString];
    kOriginIcon = [[FAKFontAwesome asteriskIconWithSize:16.0] attributedString];
    kQualityIcon = [[FAKFontAwesome starIconWithSize:16.0] attributedString];
    kQuantityIcon = [[FAKFontAwesome cubesIconWithSize:16.0] attributedString];
    kStyleIcon = [[FAKFontAwesome magicIconWithSize:16.0] attributedString];
    kTradableIcon = [[FAKFontAwesome exchangeIconWithSize:16.0] attributedString];

    kNoIcon = [[FAKFontAwesome timesIconWithSize:16.0] attributedString];
    kYesIcon = [[FAKFontAwesome checkIconWithSize:16.0] attributedString];
}

+ (id)attributeValueForType:(SCItemAttributeType)type andItem:(id <SCItem>)item {
    switch (type) {
        case SCItemAttributeTypeMarketable: return [item isMarketable] ? kYesIcon : kNoIcon;
        case SCItemAttributeTypeOrigin: return item.origin;
        case SCItemAttributeTypeQuality: return item.qualityName;
        case SCItemAttributeTypeQuantity: return item.quantity.stringValue;
        case SCItemAttributeTypeStyle: return item.style;
        case SCItemAttributeTypeTradable: return [item isTradable] ? kYesIcon : kNoIcon;
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
        case SCItemAttributeTypeMarketable:
            icon = kMarketableIcon;
            name = NSLocalizedString(kSCItemMarketable, kSCItemMarketable);
            break;
        case SCItemAttributeTypeOrigin:
            icon = kOriginIcon;
            name = NSLocalizedString(kSCItemOrigin, kSCItemOrigin);
            break;
        case SCItemAttributeTypeQuality:
            icon = kQualityIcon;
            name = NSLocalizedString(kSCItemQuality, kSCItemQuality);
            break;
        case SCItemAttributeTypeQuantity:
            icon = kQuantityIcon;
            name = NSLocalizedString(kSCItemQuantity, kSCItemQuantity);
            break;
        case SCItemAttributeTypeStyle:
            icon = kStyleIcon;
            name = NSLocalizedString(kSCItemStyle, kSCItemStyle);
            break;
        case SCItemAttributeTypeTradable:
            icon = kTradableIcon;
            name = NSLocalizedString(kSCItemTradable, kSCItemTradable);
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.defaultTabInterval = 13.0;

    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithAttributedString:icon];
    [labelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@", name]]];
    [labelText setAttributes:@{ NSParagraphStyleAttributeName: paragraphStyle } range:NSMakeRange(1, 2)];
    self.nameLabel.attributedText = labelText;

    id value = [SCItemAttributeCell attributeValueForType:type andItem:self.item];
    if ([value isKindOfClass:[NSAttributedString class]]) {
        self.valueLabel.attributedText = value;
    } else {
        self.valueLabel.text = NSLocalizedString(value, value);
    }
}

@end
