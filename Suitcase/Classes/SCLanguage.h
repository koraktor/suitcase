//
//  SCLanguage.h
//  Suitcase
//
//  Copyright (c) 2014-2015, Sebastian Staudt
//

#import <Foundation/Foundation.h>

@interface SCLanguage : NSObject

+ (NSLocale *)currentLanguage;
+ (void)setLanguage:(NSString *)l;
+ (NSString *)get:(NSString *)key;
+ (NSString *)getSettingsTitle:(NSString *)key;
+ (void)updateLanguage;

@end
