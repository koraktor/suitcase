//
//  SCDetailViewController.m
//  Suitcase
//
//  Copyright (c) 2012-2014, Sebastian Staudt
//

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "BPBarButtonItem.h"
#import "FAKFontAwesome.h"
#import "IASKSettingsReader.h"
#import "UIImageView+AFNetworking.h"

#import "SCCommunityItem.h"
#import "SCItemClassesTF2Cell.h"
#import "SCItemDescriptionCell.h"
#import "SCItemImageCell.h"
#import "SCItemTitleCell.h"
#import "SCItemAttributeCell.h"
#import "SCItemViewController.h"
#import "SCWebApiItem.h"

NSString *const kSCOpenInChrome = @"kSCOpenInChrome";
NSString *const kSCOpenInSafari = @"kSCOpenInSafari";
NSString *const kSCOpenLinkInBrowser = @"kSCOpenLinkInBrowser";

@interface SCItemViewController () {
    NSAttributedString *_itemDescription;
    NSURL *_linkUrl;
    Byte _attributes;
}
@end

@implementation SCItemViewController

static BOOL kChromeIsAvailable;
static NSRegularExpression *kHTMLRegex;

typedef enum {
    kOrigin    = 1,
    kQuality   = 2,
    kItemSet   = 4,
    kKillEater = 8
} ItemAttribute;

+ (void)initialize {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        NSError *regexError;
        kHTMLRegex = [[NSRegularExpression alloc] initWithPattern:@"<.+?>"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&regexError];
    }

    kChromeIsAvailable = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]];
}

- (void)awakeFromNib
{
    self.navigationItem.rightBarButtonItem = nil;

    FAKIcon *bookIcon = [FAKFontAwesome bookIconWithSize:0.0];
    self.wikiButton.title = [NSString stringWithFormat:@" %@ ", [bookIcon characterCode]];
    [self.wikiButton setTitleTextAttributes:@{UITextAttributeFont:[FAKFontAwesome iconFontWithSize:20.0]}
                                      forState:UIControlStateNormal];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
        [BPBarButtonItem customizeBarButtonItem:self.wikiButton withStyle:BPBarButtonItemStyleStandardDark];
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearItem)
                                                     name:@"clearItem"
                                                   object:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadItemImageCell)
                                                 name:@"itemImageLoaded"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadItemImageCell)
                                                 name:@"showColorsChanged"
                                               object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Managing the detail item

- (Byte)activeAttributes {
    Byte attributes = 0;

    if ([self.detailItem hasOrigin]) {
        attributes |= kOrigin;
    }

    if ([self.detailItem hasQuality]) {
        attributes |= kQuality;
    }

    if ([self.detailItem belongsToItemSet]) {
        attributes |= kItemSet;
    }

    if ([self.detailItem isKillEater]) {
        attributes |= kKillEater;
    }

    return attributes;
}

- (void)clearItem
{
    _detailItem = nil;

    [self performSegueWithIdentifier:@"clearItem" sender:self];
}

- (void)setDetailItem:(id <SCItem>)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;

        NSMutableAttributedString *itemDescription;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            NSString *nonHTMLItemDescription = [kHTMLRegex stringByReplacingMatchesInString:_detailItem.descriptionText
                                                                                    options:0
                                                                                      range:NSMakeRange(0, [_detailItem.descriptionText length])
                                                                               withTemplate:@""];

            itemDescription = [[NSMutableAttributedString alloc] initWithString:nonHTMLItemDescription];
        } else {
            NSError *htmlError;
            NSDictionary *options = @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding] };
            NSString *lineBrokenItemDescription = [_detailItem.descriptionText stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
            itemDescription = [[NSMutableAttributedString alloc] initWithData:[lineBrokenItemDescription dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:options
                                                                 documentAttributes:nil
                                                                              error:&htmlError];

            if (htmlError) {
                NSLog(@"Error while parsing the HTML description:\n%@", _detailItem.descriptionText);
            }
        }

        NSRange descriptionRange = NSMakeRange(0, [itemDescription length]);

        [itemDescription beginEditing];
        [itemDescription addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:16.0]
                                range:descriptionRange];
        [itemDescription addAttribute:NSForegroundColorAttributeName
                                value:[UIColor whiteColor]
                                range:descriptionRange];
        [itemDescription endEditing];

        _itemDescription = [[NSAttributedString alloc] initWithAttributedString:itemDescription];
    }
}

- (void)configureView
{
    if (_detailItem == nil) {
        [[self.view subviews] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            view.hidden = YES;
        }];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.title = nil;
        return;
    }

    if ([_detailItem class] == [SCWebApiItem class]) {
        [(SCWebApiItem *)_detailItem attributes];
    }
    _attributes = [self activeAttributes];

    if ([_detailItem.inventory.game isTF2]) {
        if (self.navigationItem.rightBarButtonItem == nil) {
            self.navigationItem.rightBarButtonItem = _wikiButton;
        }
    } else {
        if (self.navigationItem.rightBarButtonItem == _wikiButton) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self configureView];

    [super viewWillAppear:animated];
}

- (void)settingsChanged:(NSNotification *)notification {
    if ([notification.object isEqual:@"show_colors"]) {
        [self reloadItemImageCell];
    }
}

- (IBAction)showItemSet:(id)sender {
    [self performSegueWithIdentifier:@"showItemSet" sender:self];
}

- (IBAction)showWikiPage:(id)sender {
    [self performSegueWithIdentifier:@"showWikiPage" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showItemSet"] && [self.detailItem class] == [SCWebApiItem class]) {
        TTTAttributedLabel *itemSetLabel = (TTTAttributedLabel *)[[segue destinationViewController] view];
        NSString *itemSetName = [((SCWebApiItem *)self.detailItem).itemSet objectForKey:@"name"];
        NSMutableAttributedString *itemSetText = [[NSMutableAttributedString alloc] init];
        [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:itemSetName]];

        [itemSetText appendAttributedString:[[NSAttributedString alloc] init]];
        NSArray *items = [((SCWebApiItem *)self.detailItem).itemSet objectForKey:@"items"];
        [items enumerateObjectsUsingBlock:^(NSString *itemName, NSUInteger idx, BOOL *stop) {
            if ([itemSetText length] > 0) {
                [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            NSNumber *defindex = [((SCWebApiInventory *)self.detailItem.inventory).schema itemDefIndexForName:itemName];
            [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:[((SCWebApiInventory *)self.detailItem.inventory).schema itemValueForDefIndex:defindex andKey:@"item_name"]]];
        }];
        [itemSetLabel setText:itemSetText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            UIFont *nameFont;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                nameFont = [UIFont boldSystemFontOfSize:22.0];
            } else {
                nameFont = [UIFont boldSystemFontOfSize:18.0];
            }
            NSRange nameRange = [[itemSetText string] rangeOfString:itemSetName];
            [mutableAttributedString addAttributes:@{NSFontAttributeName: nameFont} range:nameRange];

            return mutableAttributedString;
        }];

        [itemSetLabel sizeToFit];
    } else if ([[segue identifier] isEqualToString:@"showWikiPage"]) {
        NSURL *wikiUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://wiki.teamfortress.com/scripts/itemredirect.php?id=%@&lang=%@", ((SCWebApiItem *)self.detailItem).defindex, [[NSLocale preferredLanguages] objectAtIndex:0]]];

        UIWebView *webView = (UIWebView *)[[segue destinationViewController] view];
        if (![webView.request.URL.absoluteURL isEqual:wikiUrl]) {
            NSURLRequest *wikiRequest = [NSURLRequest requestWithURL:wikiUrl];
            [webView loadRequest:wikiRequest];
        }
    }
}

#pragma mark - Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;

    if (indexPath.section == 0) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemTitleCell" forIndexPath:indexPath];
        ((SCItemTitleCell *)cell).item = self.detailItem;
    } else if (indexPath.section == 1) {
        SCItemImageCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemImageCell" forIndexPath:indexPath];
        cell = imageCell;
        imageCell.item = self.detailItem;
        [imageCell refresh];
    } else if (indexPath.section == 2) {
        SCItemAttributeCell *attributeCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemAttributeCell"
                                                                                       forIndexPath:indexPath];
        cell = attributeCell;
        attributeCell.value = [self itemAttributeValueForIndexPath:indexPath];

        switch ([self itemAttributeTypeForIndex:indexPath.item]) {
            case kOrigin:
                attributeCell.name = @"Origin";
                attributeCell.value = [self.detailItem origin];
                break;

            case kQuality:
                attributeCell.name = @"Quality";
                attributeCell.value = [self.detailItem qualityName];
                break;

            case kItemSet:
                attributeCell.name = @"Item set";
                attributeCell.value = ((SCWebApiItem *)self.detailItem).itemSet[@"name"];
                break;

            case kKillEater:
                attributeCell.name = @"Kill eater";
                break;

            default:
                [attributeCell empty];
        }
    } else if (indexPath.section == 3) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemDescriptionCell" forIndexPath:indexPath];
        ((SCItemDescriptionCell *)cell).descriptionText = _itemDescription;
    } else {
        SCItemClassesTF2Cell *classesTF2Cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemClassesTF2Cell" forIndexPath:indexPath];
        cell = classesTF2Cell;

        int equippedClasses = ((SCWebApiItem *)self.detailItem).equippedClasses;
        classesTF2Cell.classScoutImage.equipped = equippedClasses & 1;
        classesTF2Cell.classSoldierImage.equipped = equippedClasses & 4;
        classesTF2Cell.classPyroImage.equipped = equippedClasses & 64;
        classesTF2Cell.classDemomanImage.equipped = equippedClasses & 8;
        classesTF2Cell.classHeavyImage.equipped = equippedClasses & 32;
        classesTF2Cell.classEngineerImage.equipped = (equippedClasses & 256) != 0;
        classesTF2Cell.classMedicImage.equipped = equippedClasses & 16;
        classesTF2Cell.classSniperImage.equipped = equippedClasses & 2;
        classesTF2Cell.classSpyImage.equipped = equippedClasses & 128;

        int equippableClasses = ((SCWebApiItem *)self.detailItem).equippableClasses;
        classesTF2Cell.classScoutImage.equippable = equippableClasses & 1;
        classesTF2Cell.classSoldierImage.equippable = equippableClasses & 4;
        classesTF2Cell.classPyroImage.equippable = equippableClasses & 64;
        classesTF2Cell.classDemomanImage.equippable = equippableClasses & 8;
        classesTF2Cell.classHeavyImage.equippable = equippableClasses & 32;
        classesTF2Cell.classEngineerImage.equippable = (equippableClasses & 256) != 0;
        classesTF2Cell.classMedicImage.equippable = equippableClasses & 16;
        classesTF2Cell.classSniperImage.equippable = equippableClasses & 2;
        classesTF2Cell.classSpyImage.equippable = equippableClasses & 128;
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UIEdgeInsets insets = ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;
    CGFloat cellWidth = collectionView.frame.size.width - insets.left - insets.right;

    if (indexPath.section == 0) {
        CGSize itemTitleSize = [self.detailItem.name sizeWithFont:[UIFont boldSystemFontOfSize:22.0]
                                                constrainedToSize:CGSizeMake(cellWidth - 20.0, CGFLOAT_MAX)
                                                    lineBreakMode:NSLineBreakByWordWrapping];

        return CGSizeMake(cellWidth, itemTitleSize.height + 28.0);
    } else if (indexPath.section == 1) {
        CGFloat height;

        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.detailItem imageUrl]];
        UIImage *cachedImage = [[UIImageView sharedImageCache] cachedImageForRequest:imageRequest];
        if (cachedImage != nil) {
            height = [SCItemImageCell heightOfCellForImage:cachedImage];
        } else {
            height = 75.0;
        }

        return CGSizeMake(cellWidth, height);
    } else if (indexPath.section == 2) {
        NSString *attributeValue = [self itemAttributeValueForIndexPath:indexPath];
        CGSize attributeValueLabelSize = [attributeValue sizeWithFont:[UIFont systemFontOfSize:16.0]
                                                    constrainedToSize:CGSizeMake(170.0, CGFLOAT_MAX)
                                                        lineBreakMode:NSLineBreakByWordWrapping];
        CGFloat cellHeight = attributeValueLabelSize.height;

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            cellHeight = cellHeight + 10.0;
            cellWidth = floorf(cellWidth / 2) - 5.0;
        }

        return CGSizeMake(cellWidth, cellHeight);
    } else if (indexPath.section == 3) {
        CGRect itemDescriptionLabelRect = [_itemDescription boundingRectWithSize:CGSizeMake(cellWidth - 20.0, CGFLOAT_MAX)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                         context:nil];

        return CGSizeMake(cellWidth, itemDescriptionLabelRect.size.height + 20.0);
    } else {
        return CGSizeMake(cellWidth, [SCItemClassesTF2Cell cellHeight]);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    if (section == 2) {
        return [self numberOfItemAttributes];
    }

    return 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([self.detailItem.inventory.game isTF2]) {
        return 5;
    }

    return 4;
}

- (NSUInteger)numberOfItemAttributes {
    NSUInteger count = 0 ;
    Byte n = _attributes;
    while (n) {
        count ++;
        n &= (n - 1);
    }

    return count;
}

- (NSString *)itemAttributeValueForIndexPath:(NSIndexPath *)indexPath {
    switch ([self itemAttributeTypeForIndex:indexPath.item]) {
        case kOrigin:
            return [self.detailItem origin];

        case kQuality:
            return [self.detailItem qualityName];

        case kItemSet:
            return ((SCWebApiItem *)self.detailItem).itemSet[@"name"];

        case kKillEater:
            return [self.detailItem killEaterDescription];

        default:
            return nil;
    }
}

- (ItemAttribute)itemAttributeTypeForIndex:(NSUInteger)attributeIndex {
    NSUInteger attributeType = _attributes;
    for (int i = 0; i < attributeIndex; i ++) {
        attributeType &= attributeType - 1;
    }
    attributeType &= ~(attributeType - 1);

    return (ItemAttribute)attributeType;
}

- (void)reloadItemImageCell {
    [self.collectionView setCollectionViewLayout:[[[self.collectionView.collectionViewLayout class] alloc] init] animated:YES];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:YES];
}

#pragma mark Link handling

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        [[UIApplication sharedApplication] openURL:_linkUrl];
    } else {
        NSString *chromeUrlString = [_linkUrl absoluteString];
        chromeUrlString = [chromeUrlString substringFromIndex:[_linkUrl scheme].length];
        if ([_linkUrl.scheme isEqualToString:@"https"]) {
            chromeUrlString = [@"googlechromes" stringByAppendingString:chromeUrlString];
        } else {
            chromeUrlString = [@"googlechrome" stringByAppendingString:chromeUrlString];
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:chromeUrlString]];
    }
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    _linkUrl = url;

    NSString *title = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(kSCOpenLinkInBrowser, kSCOpenLinkInBrowser), url];
    UIActionSheet *browserSheet = [[UIActionSheet alloc] initWithTitle:title
                                                              delegate:self
                                                     cancelButtonTitle:nil
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:nil];

    [browserSheet addButtonWithTitle:NSLocalizedString(kSCOpenInSafari, kSCOpenInSafari)];
    if (kChromeIsAvailable) {
        [browserSheet addButtonWithTitle:NSLocalizedString(kSCOpenInChrome, kSCOpenInChrome)];
        browserSheet.cancelButtonIndex = 2;
    } else {
        browserSheet.cancelButtonIndex = 1;
    }
    [browserSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];

    [browserSheet showInView:self.view];
}

@end
