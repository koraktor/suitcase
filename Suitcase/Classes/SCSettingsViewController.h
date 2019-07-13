//
//  SCSettingsViewController.h
//  Suitcase
//
//  Copyright (c) 2013, Sebastian Staudt
//

#import "IASKAppSettingsViewController.h"

@interface SCSettingsViewController : IASKAppSettingsViewController <IASKSettingsDelegate>

@property (nonatomic, assign) NSBundle *defaultSettingsBundle;

- (IBAction)dismissSettings:(id)sender;

@end
