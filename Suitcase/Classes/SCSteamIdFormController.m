//
//  SCSteamIdFormController.m
//  Suitcase
//
//  Copyright (c) 2012-2013, Sebastian Staudt
//

#import "BPBarButtonItem.h"
#import "FontAwesomeKit.h"
#import "YRDropdownView.h"

#import "SCSteamIdFormController.h"

#import "SCAppDelegate.h"

@implementation SCSteamIdFormController

NSString *const kSCResolveSteamIdErrorMessage = @"kSCResolveSteamIdErrorMessage";
NSString *const kSCResolveSteamIdErrorTitle = @"kSCResolveSteamIdErrorTitle";

@synthesize helpLabel = _helpLabel;
@synthesize steamIdField = _steamIdField;

- (void)awakeFromNib
{
    [BPBarButtonItem customizeBarButtonItem:self.navigationItem.rightBarButtonItem withTintColor:[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0]];

    [super awakeFromNib];
}

- (void)resolveSteamId
{
    NSString *steamId = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID"];
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
        AFJSONRequestOperation *operation = [[SCAppDelegate webApiClient] jsonRequestForInterface:@"ISteamUser"
                                                                                        andMethod:@"ResolveVanityURL"
                                                                                       andVersion:1
                                                                                   withParameters:params];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *steamIdResponse = [responseObject objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                steamId64 = [steamIdResponse objectForKey:@"steamid"];
                SteamIdFound();
            } else {
                [_steamIdField becomeFirstResponder];

                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(kSCResolveSteamIdErrorMessage, kSCResolveSteamIdErrorMessage), [steamIdResponse objectForKey:@"message"]];

                NSDictionary *iconAttributes = @{
                                                 FAKImageAttributeForegroundColor: [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],
                                                 FAKImageAttributeShadow: @{
                                                         FAKShadowAttributeBlur: @(1.0),
                                                         FAKShadowAttributeColor: [UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0],
                                                         FAKShadowAttributeOffset: [NSValue valueWithCGSize:CGSizeMake(3.0, 3.0)]
                                                         }
                                                 };
                UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 48.0, 48.0)];
                image.image = [FontAwesomeKit imageForIcon:FAKIconWarningSign
                                                 imageSize:CGSizeMake(48.0, 48.0)
                                                  fontSize:46
                                                attributes:iconAttributes];

                YRDropdownView *errorView = [YRDropdownView dropdownInView:self.view
                                                                     title:NSLocalizedString(kSCResolveSteamIdErrorTitle, kSCResolveSteamIdErrorTitle)
                                                                    detail:errorMessage
                                                             accessoryView:image
                                                                  animated:YES];
                [errorView setBackgroundColors:@[
                 [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0],
                 [UIColor colorWithRed:0.4 green:0.0 blue:0.0 alpha:1.0]
                 ]];
                [errorView setTextColor:[UIColor lightGrayColor]];
                [errorView setTitleTextColor:[UIColor whiteColor]];
                [errorView setTitleTextShadowColor:[UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0]];
                [errorView setHideAfter:5.0];
                [YRDropdownView presentDropdown:errorView];

                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SteamID"];
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SteamID64"];
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
    [[NSUserDefaults standardUserDefaults] setObject:[self.steamIdField text]
                                              forKey:@"SteamID"];
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
}

@end
