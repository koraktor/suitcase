//
//  SCSteamIdFormController.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCSteamIdFormController.h"

#import "AFJSONRequestOperation.h"
#import "SCAppDelegate.h"

@interface SCSteamIdFormController ()

@property (weak, nonatomic) IBOutlet UITextField *steamIdField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation SCSteamIdFormController
@synthesize steamIdField;
@synthesize activityIndicator;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)submitForm:(id)sender {
    [activityIndicator startAnimating];

    SCAppDelegate *appDelegate = UIApplication.sharedApplication.delegate;

    NSString *steamId   = [self.steamIdField text];

    appDelegate.steamId64 = [[[NSNumberFormatter alloc] init] numberFromString:steamId];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *domain = [userDefaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [domain setValue:steamId forKey:@"SteamID64"];

    if (appDelegate.steamId64 == nil) {
        NSURL *steamIdUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001?vanityurl=%@&key=%@", steamId, [SCAppDelegate apiKey]]];
        AFJSONRequestOperation *steamIdOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:steamIdUrl] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            NSDictionary *steamIdResponse = [JSON objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                appDelegate.steamId64 = [steamIdResponse objectForKey:@"steamid"];
                [self dismissModalViewControllerAnimated:YES];
            } else {
                NSString *errorMsg = [NSString stringWithFormat:@"Error resolving Steam ID: %@", [JSON objectForKey:@"message"]]; 
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
            [self dismissModalViewControllerAnimated:YES];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"Error resolving 64bit Steam ID: %@", error);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while resolving the Steam ID" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];
        [steamIdOperation start];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
    }

    [activityIndicator stopAnimating];
}

- (void)viewDidUnload {
    [self setSteamIdField:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}
@end
