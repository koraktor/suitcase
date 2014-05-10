//
//  SCItemAttributeCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemAttributeCell.h"

@implementation SCItemAttributeCell

- (void)empty {
    self.nameLabel = nil;
    self.valueLabel = nil;
}

- (void)setName:(NSString *)name {
    _name = name;
    self.nameLabel.text = NSLocalizedString(name, name);
    [self.nameLabel sizeToFit];
}

- (void)setValue:(NSString *)value {
    _value = value;
    self.valueLabel.text = NSLocalizedString(value, value);
    [self.valueLabel sizeToFit];
}

@end
