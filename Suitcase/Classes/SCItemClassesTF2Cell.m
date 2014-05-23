//
//  SCItemClassesTF2Cell.m
//  Suitcase
//
//  Copyright (c) 2014, Sebastian Staudt
//

#import "SCItemClassesTF2Cell.h"

@implementation SCItemClassesTF2Cell

static CGFloat kCellHeight;

+ (void)initialize {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        kCellHeight = 94.0;
    } else {
        kCellHeight = 120.0;
    }
}

+ (CGFloat)cellHeight {
    return kCellHeight;
}

- (void)awakeFromNib {
    [self.classScoutImage setClassImageForClass:@"scout"];
    [self.classSoldierImage setClassImageForClass:@"soldier"];
    [self.classPyroImage setClassImageForClass:@"pyro"];
    [self.classDemomanImage setClassImageForClass:@"demoman"];
    [self.classHeavyImage setClassImageForClass:@"heavy"];
    [self.classEngineerImage setClassImageForClass:@"engineer"];
    [self.classMedicImage setClassImageForClass:@"medic"];
    [self.classSniperImage setClassImageForClass:@"sniper"];
    [self.classSpyImage setClassImageForClass:@"spy"];
}

@end
