//
//  SCDetailViewController.m
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+ASIHTTPRequest.h"

#import "SCItemViewController.h"

@interface SCItemViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation SCItemViewController

@synthesize detailItem = _detailItem;
@synthesize classScoutImage = _classScoutImage;
@synthesize classSoldierImage = _classSoldierImage;
@synthesize classPyroImage = _classPyroImage;
@synthesize classDemomanImage = _classDemomanImage;
@synthesize classHeavyImage = _classHeavyImage;
@synthesize classEngineerImage = _classEngineerImage;
@synthesize classMedicImage = _classMedicImage;
@synthesize classSniperImage = _classSniperImage;
@synthesize classSpyImage = _classSpyImage;
@synthesize descriptionLabel = _descriptionLabel;
@synthesize icons = _icons;
@synthesize itemImage = _itemImage;
@synthesize itemSetButton = _itemSetButton;
@synthesize killEaterIcon = _killEaterIcon;
@synthesize killEaterLabel = _killEaterLabel;
@synthesize levelLabel = _levelLabel;
@synthesize originLabel = _originLabel;
@synthesize qualityLabel = _qualityLabel;
@synthesize quantityLabel = _quantityLabel;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize wikiButton = _wikiButton;

- (void)awakeFromNib
{
    self.navigationItem.rightBarButtonItem = nil;

    [self.icons enumerateObjectsUsingBlock:^(UIImageView *icon, NSUInteger idx, BOOL *stop) {
        icon.layer.shadowColor = [UIColor blackColor].CGColor;
        icon.layer.shadowOffset = CGSizeMake(0, 1);
        icon.layer.shadowOpacity = 1;
        icon.layer.shadowRadius = 1.0;
        icon.layer.masksToBounds = NO;
    }];

    self.itemImage.layer.borderColor = [[UIColor blackColor] CGColor];
    self.itemImage.layer.cornerRadius = 5;
    self.itemImage.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.itemImage.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.itemImage.layer.shadowOpacity = 1.0;
    self.itemImage.layer.shadowRadius = 2.5;

    self.itemSetButton.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.itemSetButton.imageView.layer.shadowOffset = CGSizeMake(0, 1);
    self.itemSetButton.imageView.layer.shadowOpacity = 1;
    self.itemSetButton.imageView.layer.shadowRadius = 1.0;
    self.itemSetButton.imageView.layer.masksToBounds = NO;
    self.itemSetButton.titleLabel.numberOfLines = 2;

    self.quantityLabel.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.quantityLabel.layer.borderWidth = [[UIScreen mainScreen] scale];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(SCItem *)newDetailItem
{
    if ([newDetailItem.inventory.game isTF2]) {
        if (self.navigationItem.rightBarButtonItem == nil) {
            [self.navigationItem setRightBarButtonItem:_wikiButton animated:YES];
        }
    } else {
        if (self.navigationItem.rightBarButtonItem == _wikiButton) {
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
        }
    }

    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;

        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    [self.itemImage setImageWithURL:self.detailItem.imageUrl];

    self.title = self.detailItem.name;
    self.killEaterLabel.hidden = YES;
    self.killEaterIcon.alpha = 0.4;
    self.levelLabel.text = [NSString stringWithFormat:@"Level %@ %@",
                            self.detailItem.level, self.detailItem.itemType];
    self.originLabel.text = NSLocalizedString(self.detailItem.origin, @"Item oigin");
    self.qualityLabel.text = self.detailItem.quality;

    NSMutableString *descriptionLabelText = [self.detailItem.description mutableCopy];
    if (descriptionLabelText == nil) {
        descriptionLabelText = [NSMutableString string];
    }

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:0];
    __block BOOL firstAttribute = YES;
    [self.detailItem.attributes enumerateObjectsUsingBlock:^(NSDictionary *attribute, NSUInteger idx, BOOL *stop) {
        NSMutableString *attributeDescription = [[attribute objectForKey:@"description"] mutableCopy];
        if (attributeDescription != nil) {
            NSString *valueFormat = [attribute objectForKey:@"valueFormat"];
            NSString *value;
            if ([valueFormat isEqual:@"kill_eater"]) {
                value = [(NSNumber *)[attribute objectForKey:@"value"] stringValue];
            } else if ([valueFormat isEqual:@"value_is_account_id"]) {
                value = [[attribute objectForKey:@"accountInfo"] objectForKey:@"personaname"];
            } else if ([valueFormat isEqual:@"value_is_additive"]) {
                value = [(NSNumber *)[attribute objectForKey:@"value"] stringValue];
            } else if ([valueFormat isEqual:@"value_is_additive_percentage"]) {
                value = [[NSNumber numberWithDouble:[(NSNumber *)[attribute objectForKey:@"value"] doubleValue] * 100] stringValue];
            } else if ([valueFormat isEqual:@"value_is_date"]) {
                double timestamp = [(NSNumber *)[attribute objectForKey:@"value"] doubleValue];
                if (timestamp == 0) {
                    attributeDescription = nil;
                } else {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)[attribute objectForKey:@"value"] doubleValue]];
                    value = [NSDateFormatter localizedStringFromDate:date
                                                           dateStyle:NSDateFormatterMediumStyle
                                                           timeStyle:NSDateFormatterShortStyle];
                }
            } else if ([valueFormat isEqual:@"value_is_inverted_percentage"]) {
                NSNumber *numberValue = [NSNumber numberWithDouble:(1 - [(NSNumber *)[attribute objectForKey:@"value"] doubleValue]) * 100];
                value = [numberFormatter stringFromNumber:numberValue];
            } else if ([valueFormat isEqual:@"value_is_particle_index"]) {
                value = [self.detailItem.inventory.schema effectNameForIndex:[attribute objectForKey:@"value"]];
                if (value == nil) {
                    value = [self.detailItem.inventory.schema effectNameForIndex:[attribute objectForKey:@"floatValue"]];
                }
            } else if ([valueFormat isEqual:@"value_is_percentage"]) {
                NSNumber *numberValue = [NSNumber numberWithDouble:([(NSNumber *)[attribute objectForKey:@"value"] doubleValue] - 1) * 100];
                value = [numberFormatter stringFromNumber:numberValue];
            }

            if (attributeDescription != nil) {
                if (value != nil) {
                    [attributeDescription replaceOccurrencesOfString:@"%s1"
                                                          withString:value
                                                             options:NSLiteralSearch
                                                               range:NSMakeRange(0, [attributeDescription length])];
                }

                if ([valueFormat isEqual:@"kill_eater"]) {
                    self.killEaterLabel.text = attributeDescription;
                    CGRect currentFrame = self.killEaterLabel.frame;
                    CGSize maxFrame = CGSizeMake(currentFrame.size.width, 500);
                    CGSize expectedFrame = [attributeDescription sizeWithFont:self.killEaterLabel.font
                                                            constrainedToSize:maxFrame
                                                                lineBreakMode:self.killEaterLabel.lineBreakMode];
                    currentFrame.size.height = expectedFrame.height;
                    self.killEaterLabel.frame = currentFrame;
                    [self.killEaterLabel sizeToFit];
                    self.killEaterLabel.hidden = NO;
                    self.killEaterIcon.alpha = 1.0;
                } else {
                    if ([descriptionLabelText length] > 0) {
                        if (firstAttribute) {
                            [descriptionLabelText appendString:@"\n"];
                        }
                        [descriptionLabelText appendString:@"\n"];
                    }

                    [descriptionLabelText appendString:attributeDescription];
                    firstAttribute = NO;
                }
            }
        }
    }];
    self.descriptionLabel.text = descriptionLabelText;

    if (self.detailItem.itemSet != nil) {
        [self.itemSetButton setTitle:[self.detailItem.itemSet objectForKey:@"name"] forState:UIControlStateNormal];
        self.itemSetButton.enabled = YES;
    } else {
        [self.itemSetButton setTitle:nil forState:UIControlStateNormal];
        self.itemSetButton.enabled = NO;
    }

    if (self.detailItem) {
        CGRect currentFrame = self.descriptionLabel.frame;
        CGSize maxFrame = CGSizeMake(currentFrame.size.width, 500);
        CGSize expectedFrame = [descriptionLabelText sizeWithFont:self.descriptionLabel.font
                                                constrainedToSize:maxFrame
                                                    lineBreakMode:self.descriptionLabel.lineBreakMode];
        currentFrame.size.height = expectedFrame.height;
        self.descriptionLabel.frame = currentFrame;

        if ([self.detailItem.inventory.game isTF2]) {
            int equippedClasses = self.detailItem.equippedClasses;
            self.classScoutImage.equipped = equippedClasses & 1;
            self.classSoldierImage.equipped = equippedClasses & 4;
            self.classPyroImage.equipped = equippedClasses & 64;
            self.classDemomanImage.equipped = equippedClasses & 8;
            self.classHeavyImage.equipped = equippedClasses & 32;
            self.classEngineerImage.equipped = (equippedClasses & 256) != 0;
            self.classMedicImage.equipped = equippedClasses & 16;
            self.classSniperImage.equipped = equippedClasses & 2;
            self.classSpyImage.equipped = equippedClasses & 128;

            int equippableClasses = self.detailItem.equippableClasses;
            self.classScoutImage.equippable = equippableClasses & 1;
            self.classSoldierImage.equippable = equippableClasses & 4;
            self.classPyroImage.equippable = equippableClasses & 64;
            self.classDemomanImage.equippable = equippableClasses & 8;
            self.classHeavyImage.equippable = equippableClasses & 32;
            self.classEngineerImage.equippable = (equippableClasses & 256) != 0;
            self.classMedicImage.equippable = equippableClasses & 16;
            self.classSniperImage.equippable = equippableClasses & 2;
            self.classSpyImage.equippable = equippableClasses & 128;
        }

        [[self.view subviews] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            if ([self.classImages containsObject:view]) {
                if ([self.detailItem.inventory.game isTF2]) {
                    view.hidden = NO;
                }
            } else if (view != self.killEaterLabel) {
                view.hidden = NO;
            }
        }];

        if ([self.detailItem.quantity intValue] > 1) {
            self.quantityLabel.text = [NSString stringWithFormat:@"%@ x", self.detailItem.quantity];
            self.quantityLabel.hidden = NO;
        } else {
            self.quantityLabel.hidden = YES;
        }
    } else {
        [[self.view subviews] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            view.hidden = YES;
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.classScoutImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/scout.jpg"]];
    [self.classSoldierImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/soldier.jpg"]];
    [self.classPyroImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/pyro.jpg"]];
    [self.classDemomanImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/demoman.jpg"]];
    [self.classHeavyImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/heavy.jpg"]];
    [self.classEngineerImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/engineer.jpg"]];
    [self.classMedicImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/medic.jpg"]];
    [self.classSniperImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/sniper.jpg"]];
    [self.classSpyImage setClassImageWithURL:[NSURL URLWithString:@"http://cdn.steamcommunity.com/public/images/gamestats/440/spy.jpg"]];

    [self configureView];
}

- (void)viewDidUnload
{
    [self setClassScoutImage:nil];
    [self setClassSoldierImage:nil];
    [self setClassPyroImage:nil];
    [self setClassDemomanImage:nil];
    [self setClassHeavyImage:nil];
    [self setClassEngineerImage:nil];
    [self setClassMedicImage:nil];
    [self setClassSniperImage:nil];
    [self setClassSpyImage:nil];
    [self setDescriptionLabel:nil];
    [self setIcons:nil];
    [self setItemImage:nil];
    [self setLevelLabel:nil];
    [self setOriginLabel:nil];
    [self setQuantityLabel:nil];
    [self setQualityLabel:nil];
    [self setKillEaterLabel:nil];
    [self setKillEaterIcon:nil];

    [super viewDidUnload];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Inventory", @"Inventory");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (IBAction)showItemSet:(id)sender {
    [self performSegueWithIdentifier:@"showItemSet" sender:self];
}

- (IBAction)showWikiPage:(id)sender {
    [self performSegueWithIdentifier:@"showWikiPage" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showItemSet"]) {
        TTTAttributedLabel *itemSetLabel = (TTTAttributedLabel *)[[segue destinationViewController] view];
        NSString *itemSetName = [self.detailItem.itemSet objectForKey:@"name"];
        NSMutableAttributedString *itemSetText = [[NSMutableAttributedString alloc] init];
        [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:itemSetName]];

        [itemSetText appendAttributedString:[[NSAttributedString alloc] init]];
        NSArray *items = [self.detailItem.itemSet objectForKey:@"items"];
        [items enumerateObjectsUsingBlock:^(NSString *itemName, NSUInteger idx, BOOL *stop) {
            if ([itemSetText length] > 0) {
                [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            NSNumber *defindex = [self.detailItem.inventory.schema itemDefIndexForName:itemName];
            [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:[self.detailItem.inventory.schema itemValueForDefIndex:defindex andKey:@"item_name"]]];
        }];
        [itemSetLabel setText:itemSetText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            UIFont *nameFont;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                nameFont = [UIFont boldSystemFontOfSize:22.0];
            } else {
                nameFont = [UIFont boldSystemFontOfSize:18.0];
            }
            CTFontRef font = CTFontCreateWithName((__bridge_retained CFStringRef)nameFont.fontName, nameFont.pointSize, NULL);
            NSDictionary *nameAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)font, (NSString *)kCTFontAttributeName, nil];
            CFRelease(font);
            NSRange nameRange = [[itemSetText string] rangeOfString:itemSetName];
            [mutableAttributedString addAttributes:nameAttributes range:nameRange];

            return mutableAttributedString;
        }];

        [itemSetLabel sizeToFit];
    } else if ([[segue identifier] isEqualToString:@"showWikiPage"]) {
        NSURL *wikiUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://wiki.teamfortress.com/scripts/itemredirect.php?id=%@&lang=%@", self.detailItem.defindex, [[NSLocale preferredLanguages] objectAtIndex:0]]];

        UIWebView *webView = (UIWebView *)[[segue destinationViewController] view];
        if (![webView.request.URL.absoluteURL isEqual:wikiUrl]) {
            NSURLRequest *wikiRequest = [NSURLRequest requestWithURL:wikiUrl];
            [webView loadRequest:wikiRequest];
        }
    }
}

@end
