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
    [self.classScoutImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/scout.jpg"]];
    [self.classSoldierImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/soldier.jpg"]];
    [self.classPyroImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/pyro.jpg"]];
    [self.classDemomanImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/demoman.jpg"]];
    [self.classHeavyImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/heavy.jpg"]];
    [self.classEngineerImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/engineer.jpg"]];
    [self.classMedicImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/medic.jpg"]];
    [self.classSniperImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/sniper.jpg"]];
    [self.classSpyImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/spy.jpg"]];
}

@end
