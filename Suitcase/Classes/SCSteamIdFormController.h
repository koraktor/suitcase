//
//  SCSteamIdFormController.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

#import "SCMasterViewController.h"

@interface SCSteamIdFormController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UILabel *helpLabel;
@property (strong, nonatomic) IBOutlet UITextField *steamIdField;

- (IBAction)dismissForm:(id)sender;

@end
