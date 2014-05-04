//
//  SCItemValueCell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemValueCell.h"

@implementation SCItemValueCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    return self;
}

- (void)empty {
    self.nameLabel = nil;
    self.valueLabel = nil;
}

- (void)setName:(NSString *)name {
    _name = name;
    self.nameLabel.text = name;
    [self.nameLabel sizeToFit];
}

- (void)setValue:(NSString *)value {
    _value = value;
    self.valueLabel.text = value;
    [self.valueLabel sizeToFit];
}

@end
