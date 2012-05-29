//
//  SCSteamIdFormController.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCSteamIdFormController.h"

#import "AFJSONRequestOperation.h"
#import "SCAppDelegate.h"

@implementation SCSteamIdFormController

@synthesize steamIdField = _steamIdField;
@synthesize activityIndicator = _activityIndicator;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)submitForm:(id)sender {
    [self.activityIndicator startAnimating];

    NSString *steamId = [self.steamIdField text];
    __block NSNumber *steamId64 = [[[NSNumberFormatter alloc] init] numberFromString:steamId];
    
    void (^SteamIdFound)() = ^() {
        NSNumber *currentSteamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
        if (![currentSteamId64 isEqual:steamId64]) {
            [[NSUserDefaults standardUserDefaults] setObject:steamId64 forKey:@"SteamID64"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadInventory" object:nil];
        }
        [self dismissModalViewControllerAnimated:YES];
    };

    if (steamId64 == nil) {
        NSURL *steamIdUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001?vanityurl=%@&key=%@", steamId, [SCAppDelegate apiKey]]];
        AFJSONRequestOperation *steamIdOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:steamIdUrl] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            [self.activityIndicator stopAnimating];
            NSDictionary *steamIdResponse = [JSON objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                steamId64 = [steamIdResponse objectForKey:@"steamid"];
                SteamIdFound();
            } else {
                NSString *errorMsg = [NSString stringWithFormat:@"Error resolving Steam ID: %@", [JSON objectForKey:@"message"]]; 
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [self.activityIndicator stopAnimating];
            NSLog(@"Error resolving 64bit Steam ID: %@", error);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while resolving the Steam ID" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];
        [steamIdOperation start];
        [steamIdOperation waitUntilFinished];
    } else {
        SteamIdFound();
    }
}

- (void)viewDidUnload {
    [self setSteamIdField:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}
@end
