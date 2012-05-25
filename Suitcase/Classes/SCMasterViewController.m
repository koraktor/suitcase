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
    NSLock *_schemaLock;
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSchema) name:@"loadSchema" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadInventory) name:@"loadInventory" object:nil];
    
    _schemaLock = [[NSLock alloc] init];

    [super awakeFromNib];
}

- (void)loadInventory {    
    NSNumber *steamId64 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SteamID64"];
    NSURL *inventoryUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001?steamid=%@&key=%@", steamId64, [SCAppDelegate apiKey]]];
    AFJSONRequestOperation *inventoryOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:inventoryUrl] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *inventoryResponse = [JSON objectForKey:@"result"];
        if ([[inventoryResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSArray *itemsResponse = [inventoryResponse objectForKey:@"items"];
            [NSThread detachNewThreadSelector:@selector(populateInventoryWithData:) toTarget:self withObject:itemsResponse];
        } else {
            NSString *errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [inventoryResponse objectForKey:@"statusDetail"]]; 
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error loading inventory contents: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading the inventory contents" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];

    [inventoryOperation start];
}

- (void)loadSchema {
    NSURL *schemaUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.steampowered.com/IEconItems_440/GetSchema/v0001?key=%@&language=%@", [SCAppDelegate apiKey], [[NSLocale preferredLanguages] objectAtIndex:0]]];
    AFJSONRequestOperation *schemaOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:schemaUrl] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *schemaResponse = [JSON objectForKey:@"result"];
        if ([[schemaResponse objectForKey:@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            _itemSchema = [[SCSchema alloc] initWithDictionary:schemaResponse];
        } else {
            NSString *errorMsg = [NSString stringWithFormat:@"Error loading the inventory: %@", [schemaResponse objectForKey:@"statusDetail"]]; 
            [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        [_schemaLock unlock];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error loading game item schema: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occured while loading game item schema" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [_schemaLock unlock];
    }];

    _itemSchema = nil;
    [_schemaLock lock];
    [schemaOperation start];
}

- (void)populateInventoryWithData:(NSArray *)itemsData {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[itemsData count]];
    [_schemaLock lock];
    [itemsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [items addObject:[[SCItem alloc] initWithDictionary:obj andSchema:_itemSchema]];
    }];
    [_schemaLock unlock];
    _items = [items copy];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setDataSource:self];

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
