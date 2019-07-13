//
//  SCSettingsReader.m
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import "SCLanguage.h"

#import "SCSettingsReader.h"

@implementation SCSettingsReader

- (NSString *)titleForStringId:(NSString *)stringId {
    return [SCLanguage getSettingsTitle:stringId];
}

@end
