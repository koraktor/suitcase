//
//  SCSteamIdFormController.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCSteamIdFormController.h"

#import "ASIHTTPRequest.h"
#import "SCAppDelegate.h"

@implementation SCSteamIdFormController

@synthesize helpLabel = _helpLabel;
@synthesize steamIdField = _steamIdField;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)submitForm:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[self.steamIdField text]
                                              forKey:@"SteamID"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resolveSteamId"
                                                        object:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.text length] > 0) {
        [textField resignFirstResponder];
        [self submitForm:textField];
        return YES;
    }

    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.steamIdField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
    [self.steamIdField becomeFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.helpLabel.text = NSLocalizedString(self.helpLabel.text, @"SteamID help");
    self.navigationItem.title = NSLocalizedString(self.navigationItem.title, @"SteamID form title");
    self.navigationItem.rightBarButtonItem.enabled = ([[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"] != nil);
}

- (void)viewDidUnload {
    [self setHelpLabel:nil];
    [self setSteamIdField:nil];

    [super viewDidUnload];
}

- (IBAction)dismissForm:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end
