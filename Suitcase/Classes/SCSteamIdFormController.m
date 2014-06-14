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

NSString *const kSCResolveSteamIdErrorMessage = @"kSCResolveSteamIdErrorMessage";
NSString *const kSCResolveSteamIdErrorTitle = @"kSCResolveSteamIdErrorTitle";

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withTintColor:[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0]];
    }
}

- (void)resolveSteamId
{
    NSString *steamId = self.steamIdField.text;
    steamId = [steamId stringByReplacingOccurrencesOfString:@"(?:http://)?steamcommunity\\.com/(id|profiles)/"
                                                 withString:@""
                                                    options:NSRegularExpressionSearch
                                                      range:NSMakeRange(0, steamId.length)];
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
                                                                                          encoded:NO];
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

    self.steamIdField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.helpLabel.text = NSLocalizedString(self.helpLabel.text, @"SteamID help");
    self.navigationItem.title = NSLocalizedString(self.navigationItem.title, @"SteamID form title");
    self.navigationItem.rightBarButtonItem.enabled = ([[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"] != nil);
}

- (IBAction)dismissForm:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];

    self.steamIdField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
}

@end
