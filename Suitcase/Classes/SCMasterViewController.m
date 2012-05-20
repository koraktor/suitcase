//
//  SCMasterViewController.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import "SCMasterViewController.h"

#import "AFJSONRequestOperation.h"
#import "SCAppDelegate.h"
#import "SCDetailViewController.h"
#import "SCItem.h"
#import "SCSchema.h"

@interface SCMasterViewController () {
    NSArray *_items;
	SCSchema *_itemSchema;
    AFJSONRequestOperation *_schemaOperation; 
}
@end

@implementation SCMasterViewController

@synthesize detailViewController = _detailViewController;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }

    [self.tableView setDataSource:self];

    [self loadSchema];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadInventory) name:@"loadInventory" object:nil];

    [super awakeFromNib];
}

- (void)viewDidAppear:(BOOL)animated {
    SCAppDelegate *appDelegate = UIApplication.sharedApplication.delegate;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *domain = [userDefaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    appDelegate.steamId64 = [domain valueForKey:@"SteamID64"];
    if (appDelegate.steamId64 == nil) {
        [self.parentViewController.parentViewController performSegueWithIdentifier:@"SteamIDForm" sender:self];
    }
}

- (void)loadInventory {
    SCAppDelegate *appDelegate = UIApplication.sharedApplication.delegate;
    NSURL *inventoryUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001?steamid=%@&key=%@", appDelegate.steamId64, [SCAppDelegate apiKey]]];
    AFJSONRequestOperation *inventoryOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:inventoryUrl] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *inventoryResponse = [JSON objectForKey:@"result"];
        if ([[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSArray *itemsResponse = [inventoryResponse objectForKey:@"items"];
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:[itemsResponse count]];
            [itemsResponse enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [items addObject:[[SCItem alloc] initWithDictionary:obj andSchema:_itemSchema]];
            }];
            _items = [items copy];
            [self.tableView reloadData];
        } else {
            NSString *errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [inventoryResponse objectForKey:@"statusDetail"]]; 
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error loading inventory contents: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading the inventory contents" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [_schemaOperation waitUntilFinished];
    [inventoryOperation start];
}

- (void)loadSchema {
    NSURL *schemaUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_440/GetSchema/v0001?key=%@&language=en", [SCAppDelegate apiKey]]];
    _schemaOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:schemaUrl] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *schemaResponse = [JSON objectForKey:@"result"];
        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            _itemSchema = [[SCSchema alloc] initWithArray:[schemaResponse objectForKey:@"items"]];
        } else {
            NSString *errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [schemaResponse objectForKey:@"statusDetail"]]; 
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error loading game item schema: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading game item schema" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [_schemaOperation start];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.detailViewController = (SCDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    SCItem *item = [_items objectAtIndex:indexPath.row];
    cell.textLabel.text = item.name;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        SCItem *item = [_items objectAtIndex:indexPath.row];
        self.detailViewController.detailItem = item;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        SCItem *item = [_items objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:item];
    }
}

@end
