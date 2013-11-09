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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withTintColor:[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0]];
    }

    [super awakeFromNib];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadGames" object:nil];
        } else {
            [self dismissModalViewControllerAnimated:YES];
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
                [_steamIdField becomeFirstResponder];

                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCResolveSteamIdErrorMessage, kSCResolveSteamIdErrorMessage), [steamIdResponse objectForKey:@"message"]];

                NSShadow *iconShadow = [NSShadow new];
                [iconShadow setShadowBlurRadius:1.0];
                [iconShadow setShadowColor:[UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0]];
                [iconShadow setShadowOffset:CGSizeMake(3.0, 3.0)];
                NSDictionary *iconAttributes = @{
                                                 NSForegroundColorAttributeName: [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],
                                                 NSShadowAttributeName: iconShadow
                                               };
                UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 48.0, 48.0)];
                FAKIcon *warningIcon = [FAKFontAwesome exclamationTriangleIconWithSize:46.0];
                [warningIcon addAttributes:iconAttributes];
                image.image = [warningIcon imageWithSize:CGSizeMake(48.0, 48.0)];

                [TSMessage showNotificationInViewController:self
                                                      title:NSLocalizedString(kSCResolveSteamIdErrorTitle, kSCResolveSteamIdErrorTitle)
                                                   subtitle:errorMessage
                                                      image:nil
                                                       type:TSMessageNotificationTypeError
                                                   duration:TSMessageNotificationDurationAutomatic
                                                   callback:nil
                                                buttonTitle:nil
                                             buttonCallback:nil
                                                 atPosition:TSMessageNotificationPositionTop
                                        canBeDismisedByUser:NO];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [SCAppDelegate errorWithMessage:[error localizedDescription]];
        }];
        [operation start];
    } else {
        SteamIdFound();
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
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

    self.steamIdField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
}

@end
