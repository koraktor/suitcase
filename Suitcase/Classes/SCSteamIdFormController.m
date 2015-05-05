//
//  SCSteamIdFormController.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "TSMessage.h"

#import "SCSteamIdFormController.h"

#import "SCAppDelegate.h"

@implementation SCSteamIdFormController

NSString *const kSCSteamIdHelpText = @"kSCSteamIdHelpText";
NSString *const kSCSteamIdTitle = @"kSCSteamIdTitle";
NSString *const kSCResolveSteamIdErrorMessage = @"kSCResolveSteamIdErrorMessage";
NSString *const kSCResolveSteamIdErrorTitle = @"kSCResolveSteamIdErrorTitle";

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withTintColor:[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0]];
    }

    UIView *sampleView = [self.view.subviews lastObject];
    sampleView.frame = CGRectMake(self.view.frame.size.width / 2 - sampleView.frame.size.width / 2, sampleView.frame.origin.y, sampleView.frame.size.width, sampleView.frame.size.height);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadStrings)
                                                 name:kSCLanguageSettingChanged
                                               object:nil];

    [self reloadStrings];
}

- (void)reloadStrings
{
    self.helpLabel.text = NSLocalizedString(kSCSteamIdHelpText, kSCSteamIdHelpTitle);
    self.navigationItem.title = NSLocalizedString(kSCSteamIdTitle, kSCSteamIdTitle);

    UIBarButtonItem *cancelButton;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        cancelButton = self.toolbarItems.lastObject;
    } else {
        cancelButton = self.navigationItem.rightBarButtonItem;
    }
    cancelButton.title = NSLocalizedString(@"Cancel", "Cancel");
}

- (void)resolveSteamId
{
    NSString *steamId = self.steamIdField.text;
    steamId = [steamId stringByReplacingOccurrencesOfString:@"(?:https?://)?steamcommunity\\.com/(id|profiles)/"
                                                 withString:@""
                                                    options:NSRegularExpressionSearch
                                                      range:NSMakeRange(0, steamId.length)];
    steamId = [[steamId pathComponents] firstObject];
    __block NSNumber *steamId64 = [[[NSNumberFormatter alloc] init] numberFromString:steamId];

    void (^SteamIdFound)() = ^() {
        NSNumber *currentSteamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
        if (![currentSteamId64 isEqual:steamId64]) {
            [[NSUserDefaults standardUserDefaults] setObject:steamId forKey:@"SteamID"];
            [[NSUserDefaults standardUserDefaults] setObject:steamId64 forKey:@"SteamID64"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loadGames" object:nil];
            });
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    };

    if (steamId64 == nil) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:steamId, @"vanityUrl", nil];
        AFHTTPRequestOperation *operation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"ISteamUser"
                                                                                        andMethod:@"ResolveVanityURL"
                                                                                       andVersion:1
                                                                                   withParameters:params
                                                                                          encoded:NO
                                                                                    modifiedSince:nil];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *steamIdResponse = [responseObject objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                steamId64 = [steamIdResponse objectForKey:@"steamid"];
                SteamIdFound();
            } else {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCResolveSteamIdErrorMessage, kSCResolveSteamIdErrorMessage), [steamIdResponse objectForKey:@"message"]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [_steamIdField becomeFirstResponder];
                    [SCAppDelegate errorWithTitle:NSLocalizedString(kSCResolveSteamIdErrorTitle, kSCResolveSteamIdErrorTitle)
                                       andMessage:errorMessage
                                     inController:self];
                });
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_steamIdField becomeFirstResponder];
                [SCAppDelegate errorWithTitle:NSLocalizedString(kSCResolveSteamIdErrorTitle, kSCResolveSteamIdErrorTitle)
                                   andMessage:error.localizedDescription
                                 inController:self];
            });
        }];
        [operation start];
    } else {
        SteamIdFound();
    }
}

- (IBAction)submitForm:(id)sender {
    [self resolveSteamId];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.text length] > 0) {
        [textField resignFirstResponder];
        [self submitForm:textField];
        return YES;
    }

    return NO;
}

- (void)viewDidLayoutSubviews {
   [self.steamIdField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationItem.rightBarButtonItem.enabled = ([[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"] != nil);

    self.steamIdField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
}

- (IBAction)dismissForm:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];

    self.steamIdField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
}

@end
