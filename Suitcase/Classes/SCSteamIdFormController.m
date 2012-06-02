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
        __unsafe_unretained __block ASIHTTPRequest *steamIdRequest = [ASIHTTPRequest requestWithURL:steamIdUrl];
        [steamIdRequest setCompletionBlock:^{
            NSError *error = nil;
            NSDictionary *steamIdResponse = [[NSJSONSerialization JSONObjectWithData:[steamIdRequest responseData] options:0 error:&error] objectForKey:@"response"];
            if ([[steamIdResponse objectForKey:@"success"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                steamId64 = [steamIdResponse objectForKey:@"steamid"];
                SteamIdFound();
            } else {
                NSString *errorMsg = [NSString stringWithFormat:@"Error resolving Steam ID: %@", [steamIdResponse objectForKey:@"message"]];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        }];

        [steamIdRequest startSynchronous];
    } else {
        SteamIdFound();
    }
}

- (void)viewDidUnload {
    [self setSteamIdField:nil];

    [super viewDidUnload];
}
@end
