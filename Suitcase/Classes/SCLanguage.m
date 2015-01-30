//
//  SCLanguage.m
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import "SCLanguage.h"

@implementation SCLanguage

static NSBundle *bundle = nil;
static NSBundle *iaskBundle = nil;
static NSBundle *iaskRootBundle = nil;

+ (void)initialize {
    iaskRootBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"InAppSettings"
                                                                              ofType:@"bundle"]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentLanguage = [defaults objectForKey:@"language"];
    if ([currentLanguage isEqualToString:@"auto"]) {
        currentLanguage = [defaults objectForKey:@"AppleLanguages"][0];
    }
    [self setLanguage:currentLanguage];
}

+ (NSLocale *)currentLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentLanguage = [defaults stringForKey:@"language"];

    if ([currentLanguage isEqualToString:@"auto"]) {
        currentLanguage = [defaults objectForKey:@"AppleLanguages"][0];
    }

    return [NSLocale localeWithLocaleIdentifier:currentLanguage];
}

+ (void)setLanguage:(NSString *)l {
    NSLog(@"preferredLang: %@", l);
    NSString *path = [[NSBundle mainBundle] pathForResource:l ofType:@"lproj" ];
    bundle = [NSBundle bundleWithPath:path];
    path = [iaskRootBundle pathForResource:l ofType:@"lproj" ];
    iaskBundle = [NSBundle bundleWithPath:path];
}

+ (NSString *)get:(NSString *)key {
    return [bundle localizedStringForKey:key value:key table:nil];
}

+ (NSString *)getSettingsTitle:(NSString *)key {
    return [iaskBundle localizedStringForKey:key value:key table:@"Root"];
}

+ (void)updateLanguage {
    [SCLanguage setLanguage:[[SCLanguage currentLanguage] localeIdentifier]];
}

@end
