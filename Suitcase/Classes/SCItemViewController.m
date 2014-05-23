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

#import "SCImageCache.h"
#import "SCItemClassesTF2Cell.h"
#import "SCItemDescriptionCell.h"
#import "SCItemImageCell.h"
#import "SCItemSetCell.h"
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
    kSCCellTypeTitle,
    kSCCellTypeImage,
    kSCCellTypeAttribute,
    kSCCellTypeDescription,
    kSCCellTypeItemSet,
    kSCCellTypeClassesTF2
} SCCellType;

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
    [super awakeFromNib];

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
                                             selector:@selector(reloadItemImageCell:)
                                                 name:@"itemImageLoaded"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadItemImageCell:)
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

    if ([self.item hasOrigin]) {
        attributes |= SCItemAttributeTypeOrigin;
    }

    if ([self.item hasQuality]) {
        attributes |= SCItemAttributeTypeQuality;
    }

    return attributes;
}

- (void)clearItem
{
    self.item = nil;

    [self performSegueWithIdentifier:@"clearItem" sender:self];
}

- (void)setItem:(id <SCItem>)item
{
    if (_item != item) {
        _item = item;

        NSMutableAttributedString *itemDescription;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            NSString *nonHTMLItemDescription = [kHTMLRegex stringByReplacingMatchesInString:self.item.descriptionText
                                                                                    options:0
                                                                                      range:NSMakeRange(0, [self.item.descriptionText length])
                                                                               withTemplate:@""];

            itemDescription = [[NSMutableAttributedString alloc] initWithString:nonHTMLItemDescription];
        } else {
            NSError *htmlError;
            NSDictionary *options = @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding] };
            NSString *lineBrokenItemDescription = [self.item.descriptionText stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
            itemDescription = [[NSMutableAttributedString alloc] initWithData:[lineBrokenItemDescription dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:options
                                                                 documentAttributes:nil
                                                                              error:&htmlError];

            if (htmlError) {
                NSLog(@"Error while parsing the HTML description:\n%@", self.item.descriptionText);
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
    if (self.item == nil) {
        [[self.view subviews] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            view.hidden = YES;
        }];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.title = nil;
        return;
    }

    if ([self.item isKindOfClass:[SCWebApiItem class]]) {
        [(SCWebApiItem *)self.item attributes];
    }
    _attributes = [self activeAttributes];

    if ([self.item.inventory.game isTF2]) {
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
        [self reloadItemImageCell:notification];
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
    if ([[segue identifier] isEqualToString:@"showItemSet"] && [self.item isKindOfClass:[SCWebApiItem class] ]) {
        TTTAttributedLabel *itemSetLabel = (TTTAttributedLabel *)[[segue destinationViewController] view];
        NSString *itemSetName = [((SCWebApiItem *)self.item).itemSet objectForKey:@"name"];
        NSMutableAttributedString *itemSetText = [[NSMutableAttributedString alloc] init];
        [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:itemSetName]];

        [itemSetText appendAttributedString:[[NSAttributedString alloc] init]];
        NSArray *items = [((SCWebApiItem *)self.item).itemSet objectForKey:@"items"];
        [items enumerateObjectsUsingBlock:^(NSString *itemName, NSUInteger idx, BOOL *stop) {
            if ([itemSetText length] > 0) {
                [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            NSNumber *defindex = [((SCWebApiInventory *)self.item.inventory).schema itemDefIndexForName:itemName];
            [itemSetText appendAttributedString:[[NSAttributedString alloc] initWithString:[((SCWebApiInventory *)self.item.inventory).schema itemValueForDefIndex:defindex andKey:@"item_name"]]];
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
        NSURL *wikiUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://wiki.teamfortress.com/scripts/itemredirect.php?id=%@&lang=%@", ((SCWebApiItem *)self.item).defindex, [[NSLocale preferredLanguages] objectAtIndex:0]]];

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

    switch (indexPath.section) {
        case kSCCellTypeAttribute: {
            SCItemAttributeCell *attributeCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemAttributeCell"                                                                                           forIndexPath:indexPath];
            cell = attributeCell;
            attributeCell.item = self.item;
            attributeCell.type = [self itemAttributeTypeForIndex:indexPath.item];
            break;
        }

        case kSCCellTypeClassesTF2: {
            SCItemClassesTF2Cell *classesTF2Cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemClassesTF2Cell" forIndexPath:indexPath];
            cell = classesTF2Cell;

            int equippedClasses = ((SCWebApiItem *)self.item).equippedClasses;
            classesTF2Cell.classScoutImage.equipped = equippedClasses & 1;
            classesTF2Cell.classSoldierImage.equipped = equippedClasses & 4;
            classesTF2Cell.classPyroImage.equipped = equippedClasses & 64;
            classesTF2Cell.classDemomanImage.equipped = equippedClasses & 8;
            classesTF2Cell.classHeavyImage.equipped = equippedClasses & 32;
            classesTF2Cell.classEngineerImage.equipped = (equippedClasses & 256) != 0;
            classesTF2Cell.classMedicImage.equipped = equippedClasses & 16;
            classesTF2Cell.classSniperImage.equipped = equippedClasses & 2;
            classesTF2Cell.classSpyImage.equipped = equippedClasses & 128;

            int equippableClasses = ((SCWebApiItem *)self.item).equippableClasses;
            classesTF2Cell.classScoutImage.equippable = equippableClasses & 1;
            classesTF2Cell.classSoldierImage.equippable = equippableClasses & 4;
            classesTF2Cell.classPyroImage.equippable = equippableClasses & 64;
            classesTF2Cell.classDemomanImage.equippable = equippableClasses & 8;
            classesTF2Cell.classHeavyImage.equippable = equippableClasses & 32;
            classesTF2Cell.classEngineerImage.equippable = (equippableClasses & 256) != 0;
            classesTF2Cell.classMedicImage.equippable = equippableClasses & 16;
            classesTF2Cell.classSniperImage.equippable = equippableClasses & 2;
            classesTF2Cell.classSpyImage.equippable = equippableClasses & 128;

            break;
        }

        case kSCCellTypeDescription:
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemDescriptionCell" forIndexPath:indexPath];
            ((SCItemDescriptionCell *)cell).descriptionText = _itemDescription;
            break;

        case kSCCellTypeImage: {
            SCItemImageCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemImageCell" forIndexPath:indexPath];
            cell = imageCell;
            imageCell.item = self.item;
            [imageCell refresh];
            break;
        }

        case kSCCellTypeItemSet:
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemSetCell" forIndexPath:indexPath];
            ((SCItemSetCell *)cell).item = self.item;
            break;

        case kSCCellTypeTitle:
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemTitleCell" forIndexPath:indexPath];
            ((SCItemTitleCell *)cell).item = self.item;
            break;

        default:
            cell = [[UICollectionViewCell alloc] init];
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UIEdgeInsets insets = ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;
    CGFloat cellWidth = collectionView.frame.size.width - insets.left - insets.right;

    switch (indexPath.section) {
        case kSCCellTypeAttribute: {
            NSString *attributeValue = [SCItemAttributeCell attributeValueForType:[self itemAttributeTypeForIndex:indexPath.item]
                                                                          andItem:self.item];
            CGSize attributeValueLabelSize = [attributeValue sizeWithFont:[UIFont systemFontOfSize:16.0]
                                                        constrainedToSize:CGSizeMake(170.0, CGFLOAT_MAX)
                                                            lineBreakMode:NSLineBreakByWordWrapping];
            CGFloat cellHeight = attributeValueLabelSize.height + 10.0;

            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                cellWidth = floorf(cellWidth / 2) - 5.0;
            }

            return CGSizeMake(cellWidth, cellHeight);
        }

        case kSCCellTypeClassesTF2:
            return CGSizeMake(cellWidth, [SCItemClassesTF2Cell cellHeight]);

        case kSCCellTypeDescription: {
            CGRect itemDescriptionLabelRect = [_itemDescription boundingRectWithSize:CGSizeMake(cellWidth - 20.0, CGFLOAT_MAX)
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                                             context:nil];

            return CGSizeMake(cellWidth, itemDescriptionLabelRect.size.height + 20.0);
        }

        case kSCCellTypeImage: {
            CGFloat height;
            UIImage *cachedImage = [SCImageCache cachedImageForItem:self.item];
            if (cachedImage != nil) {
                height = [SCItemImageCell heightOfCellForImage:cachedImage];
            } else {
                height = 75.0;
            }

            return CGSizeMake(cellWidth, height);
        }

        case kSCCellTypeItemSet: {
            CGSize nameLabelSize = [self.item.itemSet.name sizeWithFont:[UIFont systemFontOfSize:16.0]
                                                      constrainedToSize:CGSizeMake(290.0, CGFLOAT_MAX)
                                                          lineBreakMode:NSLineBreakByWordWrapping];
            return CGSizeMake(cellWidth, nameLabelSize.height + 35.0);
        }

        case kSCCellTypeTitle: {
            CGSize itemTitleSize = [self.item.name sizeWithFont:[UIFont boldSystemFontOfSize:22.0]
                                              constrainedToSize:CGSizeMake(cellWidth - 20.0, CGFLOAT_MAX)
                                                  lineBreakMode:NSLineBreakByWordWrapping];

            return CGSizeMake(cellWidth, itemTitleSize.height + 28.0);
        }

        default:
            return CGSizeZero;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case kSCCellTypeAttribute:
            return [self numberOfItemAttributes];

        case kSCCellTypeClassesTF2:
            return ([self.item.inventory.game isTF2]) ? 1 : 0;

        case kSCCellTypeDescription:
            return (self.item.descriptionText.length == 0) ? 0 : 1;

        case kSCCellTypeItemSet:
            return ([self.item belongsToItemSet]) ? 1 : 0;

        default:
            return 1;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return kSCCellTypeClassesTF2 + 1;
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

- (SCItemAttributeType)itemAttributeTypeForIndex:(NSUInteger)attributeIndex {
    NSUInteger attributeType = _attributes;
    for (int i = 0; i < attributeIndex; i ++) {
        attributeType &= attributeType - 1;
    }
    attributeType &= ~(attributeType - 1);

    return (SCItemAttributeType)attributeType;
}

- (void)reloadItemImageCell:(NSNotification *)notification {
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:kSCCellTypeImage]];
    } completion:^(BOOL finished) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:kSCCellTypeTitle]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:YES];

        if ([notification.object isKindOfClass:[SCItemImageCell class]]) {
            SCItemImageCell *imageCell = notification.object;
            if (imageCell.imageView.hidden) {
                [imageCell.activityIndicator stopAnimating];
                imageCell.imageView.hidden = NO;
            }
        }
    }];
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
