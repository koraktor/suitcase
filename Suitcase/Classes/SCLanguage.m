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
    if (currentLanguage == nil || [currentLanguage isEqualToString:@"auto"]) {
        currentLanguage = [NSLocale preferredLanguages][0];
    }
    [self setLanguage:currentLanguage];
}

+ (NSLocale *)currentLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentLanguage = [defaults stringForKey:@"language"];

    if (currentLanguage == nil || [currentLanguage isEqualToString:@"auto"]) {
        currentLanguage = [NSLocale preferredLanguages][0];
    }

    return [NSLocale localeWithLocaleIdentifier:currentLanguage];
}

+ (void)setLanguage:(NSString *)lang {
#if DEBUG
    NSLog(@"Changing preferred language to: %@", lang);
#endif

    NSString *path = [[NSBundle mainBundle] pathForResource:lang ofType:@"lproj" ];

    if (path == nil) {
#if DEBUG
        NSLog(@"%@ unavailable, falling back to en.", lang);
#endif

        lang = @"en";
        path = [[NSBundle mainBundle] pathForResource:lang ofType:@"lproj" ];
    }

    bundle = [NSBundle bundleWithPath:path];
    path = [iaskRootBundle pathForResource:lang ofType:@"lproj" ];
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
